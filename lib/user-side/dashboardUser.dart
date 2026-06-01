// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';
import 'detailReport.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────
class ReportItem {
  final int id;
  final String title, address, tanggal, status, jenis, fileUrl;
  final double? latitude, longitude;

  const ReportItem({
    required this.id,
    required this.title,
    required this.address,
    required this.tanggal,
    required this.status,
    required this.jenis,
    this.latitude,
    this.longitude,
    this.fileUrl = '',
  });

  factory ReportItem.fromMap(Map<String, dynamic> m) {
    String fmt = '';
    try {
      final dt = DateTime.parse(m['created_at'] as String);
      fmt = DateFormat('d MMM yyyy', 'id').format(dt.toLocal());
    } catch (_) {
      fmt = m['tanggal']?.toString() ?? '';
    }
    return ReportItem(
      id: m['id'] as int,
      title: m['title'] as String? ?? '(tanpa judul)',
      address: m['address'] as String? ?? '',
      tanggal: fmt,
      status: m['status'] as String? ?? 'pending',
      jenis: m['jenis'] as String? ?? 'kerusakan',
      latitude: (m['latitude'] as num?)?.toDouble(),
      longitude: (m['longitude'] as num?)?.toDouble(),
      fileUrl: m['file_url'] as String? ?? '',
    );
  }

  DetailReportItem toDetailItem() {
    final urls = fileUrl.isNotEmpty
        ? fileUrl
              .split(',')
              .map((u) => u.trim())
              .where((u) => u.isNotEmpty)
              .toList()
        : <String>[];
    return DetailReportItem(
      id: id,
      title: title,
      address: address,
      tanggal: tanggal,
      status: status,
      jenis: jenis,
      fileUrls: urls,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────
class DashboardUser extends StatelessWidget {
  const DashboardUser({super.key});
  @override
  Widget build(BuildContext context) => const _DashboardPage();
}

class _DashboardPage extends StatefulWidget {
  const _DashboardPage();
  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  final _db = Supabase.instance.client;
  List<ReportItem> _reports = [];
  String _namaUser = '', _inisial = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = _db.auth.currentUser;
      if (user == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      try {
        final prof = await _db
            .from('profiles')
            .select('display_name')
            .eq('id', user.id)
            .maybeSingle();
        if (prof != null) {
          final nama = prof['display_name'] as String? ?? user.email ?? '';
          _namaUser = nama;
          _inisial = nama
              .trim()
              .split(' ')
              .where((w) => w.isNotEmpty)
              .take(2)
              .map((w) => w[0].toUpperCase())
              .join();
        } else {
          _namaUser = user.email ?? '';
          _inisial = _namaUser.isNotEmpty ? _namaUser[0].toUpperCase() : '?';
        }
      } catch (_) {
        _namaUser = user.email ?? '';
        _inisial = _namaUser.isNotEmpty ? _namaUser[0].toUpperCase() : '?';
      }
      final rows = await _db
          .from('reports')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      setState(() {
        _reports = (rows as List).map((r) => ReportItem.fromMap(r)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int get _total => _reports.length;
  int get _pending => _reports.where((r) => r.status == 'pending').length;
  int get _proses => _reports.where((r) => r.status == 'proses').length;
  int get _selesai => _reports.where((r) => r.status == 'selesai').length;

  List<ReportItem> get _preview => _reports.take(5).toList();

  Future<void> _logout() async {
    await _db.auth.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  void _openDetail(ReportItem r) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => DetailReportPage(item: r.toDetailItem())),
  );

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      body: SafeArea(
        child: _loading
            ? const LoadingCenter()
            : _error != null
            ? ErrorCenter(message: _error!, onRetry: _fetchAll)
            : RefreshIndicator(
                onRefresh: _fetchAll,
                color: kBlueBright,
                backgroundColor: kNavy2,
                // Pakai LayoutBuilder agar tahu tinggi layar yang tersedia
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        // Minimal setinggi layar agar konten selalu penuh
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Header ─────────────────────────────────
                              _buildHeader(),
                              const SizedBox(height: 10),

                              // ── Stats — mengisi sisa lebar ─────────────
                              _buildStatsRow(),
                              const SizedBox(height: 14),

                              // ── Laporan saya ───────────────────────────
                              SectionHeader(
                                title: 'Laporan saya',
                                actionLabel: 'Lihat semua →',
                                onAction: () => Navigator.pushNamed(
                                  context,
                                  '/userHistoryReport',
                                ),
                              ),
                              const SizedBox(height: 8),

                              // 5 laporan terbaru, jarak merata mengisi ruang
                              _buildLaporanListFill(constraints.maxHeight),

                              const SizedBox(height: 12),

                              // ── Status + Tips ──────────────────────────
                              _buildBottomRow(),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [kBlue, kBlueBright],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            _inisial,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _namaUser,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const Text(
                'Warga · Surabaya',
                style: TextStyle(color: kTextMuted, fontSize: 10),
              ),
            ],
          ),
        ),
        _HeaderBtn(
          icon: Icons.logout_rounded,
          bg: const Color(0xFFB71C1C),
          onTap: _logout,
        ),
        const SizedBox(width: 6),
        _HeaderBtn(icon: Icons.settings_outlined, bg: kBlue, onTap: () {}),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () async {
            await Navigator.pushNamed(context, '/createReport');
            _fetchAll();
          },
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: kGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.add, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'Buat laporan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  // ── Stats —
  Widget _buildStatsRow() => IntrinsicHeight(
    child: Row(
      children: [
        _StatChip(
          icon: Icons.description_outlined,
          label: 'Total',
          value: '$_total',
          color: Colors.white,
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.access_time_outlined,
          label: 'Menunggu',
          value: '$_pending',
          color: kAmber,
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.build_outlined,
          label: 'Diproses',
          value: '$_proses',
          color: kBlueTag,
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.check_circle_outline,
          label: 'Selesai',
          value: '$_selesai',
          color: kGreen,
        ),
      ],
    ),
  );

  // ── Laporan list —
  Widget _buildLaporanListFill(double screenHeight) {
    if (_preview.isEmpty) {
      return Container(
        height: screenHeight * 0.28,
        alignment: Alignment.center,
        child: AppCard(
          padding: const EdgeInsets.all(16),
          child: const Center(
            child: Text(
              'Belum ada laporan.\nTap "Buat laporan" untuk mulai.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextDim, fontSize: 12),
            ),
          ),
        ),
      );
    }
    const overhead = 60 + 52 + 20 + 160 + 70.0;
    final availableForList = (screenHeight - overhead).clamp(
      160.0,
      double.infinity,
    );
    final slotCount = _preview.length;
    final cardHeight = (availableForList / slotCount).clamp(44.0, 90.0);

    return SizedBox(
      height: availableForList,
      child: Column(
        children: _preview
            .map(
              (r) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: _LaporanCard(
                    report: r,
                    onTap: () => _openDetail(r),
                    // Kirim tinggi agar card bisa menyesuaikan
                    forcedHeight: cardHeight - 7,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── Status + Tips side by side ─────────────────────────────────────────────
  Widget _buildBottomRow() {
    final total = _total == 0 ? 1 : _total;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: kCardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Status keseluruhan', style: kStyleSectionTitle),
                  const SizedBox(height: 10),
                  _StatusBar(
                    label: 'Selesai',
                    count: '$_selesai/$_total',
                    ratio: _selesai / total,
                    color: kGreen,
                  ),
                  const SizedBox(height: 7),
                  _StatusBar(
                    label: 'Diproses',
                    count: '$_proses/$_total',
                    ratio: _proses / total,
                    color: kBlueTag,
                  ),
                  const SizedBox(height: 7),
                  _StatusBar(
                    label: 'Menunggu',
                    count: '$_pending/$_total',
                    ratio: _pending / total,
                    color: kAmber,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: kCardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tips pelaporan', style: kStyleSectionTitle),
                  const SizedBox(height: 10),
                  _TipItem(
                    icon: Icons.camera_alt_outlined,
                    title: 'Upload foto yang jelas',
                    desc: 'Foto dekat & jauh percepat verifikasi.',
                  ),
                  _TipItem(
                    icon: Icons.location_on_outlined,
                    title: 'Aktifkan GPS saat melapor',
                    desc: 'Koordinat akurat bantu tim lapangan.',
                  ),
                  _TipItem(
                    icon: Icons.description_outlined,
                    title: 'Deskripsi yang detail',
                    desc: 'Panjang, kedalaman & risiko kerusakan.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUB-WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final VoidCallback onTap;
  const _HeaderBtn({required this.icon, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: 16),
    ),
  );
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kNavy2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 12),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(color: kTextDim, fontSize: 9),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    ),
  );
}

class _LaporanCard extends StatelessWidget {
  final ReportItem report;
  final VoidCallback onTap;
  final double? forcedHeight;
  const _LaporanCard({
    required this.report,
    required this.onTap,
    this.forcedHeight,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor, iconBg) = statusIconStyle(report.status);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: forcedHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        decoration: kCardDecoration,
        alignment: Alignment.center,
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    style: kStyleCardTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: kTextDim,
                        size: 10,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${report.address}  ·  ${report.tanggal}',
                          style: kStyleDim,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(status: report.status),
          ],
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final String label, count;
  final double ratio;
  final Color color;
  const _StatusBar({
    required this.label,
    required this.count,
    required this.ratio,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: kStyleMuted),
          Text(count, style: kStyleMuted),
        ],
      ),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: ratio.clamp(0.0, 1.0),
          minHeight: 4,
          backgroundColor: Colors.white.withOpacity(0.08),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    ],
  );
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String title, desc;
  const _TipItem({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: kNavy3,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: kBlueBright, size: 13),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: kStyleCardTitle),
              Text(
                desc,
                style: const TextStyle(
                  color: kTextDim,
                  fontSize: 10,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
