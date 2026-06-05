// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_colors.dart';
import '../app_widgets.dart';

// ── Model ─────────────────────────────────────────────────────────────────
class ReportItem {
  final int    id;
  final String title;
  final String address;
  final String tanggal;
  final String status;
  final String jenis;
  final double? latitude;
  final double? longitude;

  const ReportItem({
    required this.id,
    required this.title,
    required this.address,
    required this.tanggal,
    required this.status,
    required this.jenis,
    this.latitude,
    this.longitude,
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
      id:        m['id']        as int,
      title:     m['title']     as String? ?? '(tanpa judul)',
      address:   m['address']   as String? ?? '',
      tanggal:   fmt,
      status:    m['status']    as String? ?? 'pending',
      jenis:     m['jenis']     as String? ?? 'kerusakan',
      latitude:  (m['latitude']  as num?)?.toDouble(),
      longitude: (m['longitude'] as num?)?.toDouble(),
    );
  }
}

// ── DashboardUser — entry point ───────────────────────────────────────────
class DashboardUser extends StatelessWidget {
  const DashboardUser({super.key});

  @override
  Widget build(BuildContext context) => const _DashboardPage();
}

// ── _DashboardPage ────────────────────────────────────────────────────────
class _DashboardPage extends StatefulWidget {
  const _DashboardPage();

  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  final _db = Supabase.instance.client;

  List<ReportItem> _reports = [];
  String  _namaUser = '';
  String  _inisial  = '';
  bool    _loading  = true;
  String? _error;

  // ── Fetch ─────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = _db.auth.currentUser;
      if (user == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      // Profil user
      try {
        final prof = await _db
            .from('profiles')
            .select('display_name')
            .eq('id', user.id)
            .maybeSingle();

        if (prof != null) {
          final nama = prof['display_name'] as String? ?? user.email ?? '';
          _namaUser = nama;
          _inisial  = nama.trim().split(' ')
              .where((w) => w.isNotEmpty)
              .take(2)
              .map((w) => w[0].toUpperCase())
              .join();
        } else {
          final email = user.email ?? '';
          _namaUser = email;
          _inisial  = email.isNotEmpty ? email[0].toUpperCase() : '?';
        }
      } catch (_) {
        final email = user.email ?? '';
        _namaUser = email;
        _inisial  = email.isNotEmpty ? email[0].toUpperCase() : '?';
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
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Stats ─────────────────────────────────────────────────────────────────
  int get _total   => _reports.length;
  int get _pending => _reports.where((r) => r.status == 'pending').length;
  int get _proses  => _reports.where((r) => r.status == 'proses').length;
  int get _selesai => _reports.where((r) => r.status == 'selesai').length;

  List<ReportItem> get _preview => _reports.take(4).toList();

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> _logout() async {
    await _db.auth.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: kBlueBright))
            : _error != null
                ? _buildError()
                : RefreshIndicator(
                    onRefresh: _fetchAll,
                    color: kBlueBright,
                    backgroundColor: kNavy2,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 4),
                          _buildStatsRow(),
                          const SizedBox(height: 24),
                          SectionTitle(
                            title: 'Laporan saya',
                            actionLabel: 'Lihat semua →',
                            onAction: () => Navigator.pushNamed(context, '/userHistoryReport'),
                          ),
                          const SizedBox(height: 12),
                          _buildLaporanList(),
                          const SizedBox(height: 24),
                          _buildTwoCol(_buildPetaPanel(), _buildTimelinePanel()),
                          const SizedBox(height: 12),
                          _buildTwoCol(_buildStatusPanel(), _buildNotifPanel()),
                          const SizedBox(height: 24),
                          const _TipsSection(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────
  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: kRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.error_outline_rounded, color: kRed, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(color: kTextMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Coba lagi', onPressed: _fetchAll),
        ],
      ),
    ),
  );

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
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
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _namaUser,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const Text(
                  'Warga · Surabaya',
                  style: TextStyle(color: kTextMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          // Action buttons
          AppIconBtn(
            icon: Icons.logout_rounded,
            onTap: _logout,
            iconColor: Colors.white,
            bgColor: const Color(0xFFB71C1C),
          ),
          const SizedBox(width: 8),
          AppIconBtn(
            icon: Icons.settings_outlined,
            onTap: () {},
            iconColor: Colors.white,
            bgColor: kBlue,
          ),
          const SizedBox(width: 8),
          // Tombol buat laporan
          GestureDetector(
            onTap: () async {
              await Navigator.pushNamed(context, '/createReport');
              _fetchAll();
            },
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: kGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Buat laporan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Grid ────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (ctx, c) {
          final cols = c.maxWidth < 360 ? 2 : 4;
          return GridView.count(
            crossAxisCount: cols,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: cols == 4 ? 0.85 : 1.3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _StatCard(
                icon: Icons.description_outlined,
                label: 'Total laporan',
                value: '$_total',
                sub: 'Sejak bergabung',
                valueColor: Colors.white,
              ),
              _StatCard(
                icon: Icons.access_time_outlined,
                label: 'Menunggu',
                value: '$_pending',
                sub: 'Belum ditangani',
                valueColor: kAmber,
              ),
              _StatCard(
                icon: Icons.build_outlined,
                label: 'Diproses',
                value: '$_proses',
                sub: 'Sedang dikerjakan',
                valueColor: kBlueTag,
              ),
              _StatCard(
                icon: Icons.check_circle_outline,
                label: 'Selesai',
                value: '$_selesai',
                sub: 'Berhasil diperbaiki',
                valueColor: kGreen,
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Laporan list (4 terbaru) ──────────────────────────────────────────────
  Widget _buildLaporanList() {
    if (_preview.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AppPanel(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const Icon(Icons.inbox_outlined, color: kTextDim, size: 32),
                  const SizedBox(height: 10),
                  const Text(
                    'Belum ada laporan.',
                    style: TextStyle(color: kTextMuted, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap "Buat laporan" untuk mulai.',
                    style: TextStyle(color: kTextDim, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _preview.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _LaporanCard(report: r),
        )).toList(),
      ),
    );
  }

  // ── Peta panel ────────────────────────────────────────────────────────────
  Widget _buildPetaPanel() {
    final dots = _reports
        .where((r) => r.latitude != null && r.longitude != null)
        .take(8)
        .toList();

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Peta laporan saya',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/map'),
                child: const Text(
                  'Buka peta ↗',
                  style: TextStyle(color: kBlueBright, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: kNavy3,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CustomPaint(
                painter: _MapPainter(reports: dots),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${dots.length} titik dilaporkan',
            style: const TextStyle(color: kTextDim, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ── Timeline panel ────────────────────────────────────────────────────────
  Widget _buildTimelinePanel() {
    final aktif = _reports.firstWhere(
      (r) => r.status != 'selesai',
      orElse: () => _reports.isNotEmpty
          ? _reports.first
          : const ReportItem(
              id: 0, title: '', address: '', tanggal: '',
              status: 'pending', jenis: 'kerusakan'),
    );

    final steps = [
      {'label': 'Laporan dikirim',    'statuses': ['pending', 'proses', 'selesai']},
      {'label': 'Diverifikasi admin', 'statuses': ['proses', 'selesai']},
      {'label': 'Pekerja ditugaskan', 'statuses': ['proses', 'selesai']},
      {'label': 'Perbaikan selesai',  'statuses': ['selesai']},
    ];

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Laporan aktif terbaru',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          if (_reports.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Belum ada laporan aktif.',
                style: TextStyle(color: kTextDim, fontSize: 12),
              ),
            )
          else ...[
            const SizedBox(height: 6),
            Text(
              aktif.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: kTextMuted, fontSize: 11),
            ),
            const SizedBox(height: 10),
            ...steps.map((s) => _TimelineItem(
              label: s['label'] as String,
              done: (s['statuses'] as List<String>).contains(aktif.status),
            )),
          ],
        ],
      ),
    );
  }

  // ── Status panel ──────────────────────────────────────────────────────────
  Widget _buildStatusPanel() {
    final total = _total == 0 ? 1 : _total;
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status keseluruhan',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          _StatusBar(label: 'Selesai',  count: '$_selesai / $_total', ratio: _selesai / total, color: kGreen),
          const SizedBox(height: 8),
          _StatusBar(label: 'Diproses', count: '$_proses / $_total',  ratio: _proses  / total, color: kBlueTag),
          const SizedBox(height: 8),
          _StatusBar(label: 'Menunggu', count: '$_pending / $_total', ratio: _pending / total, color: kAmber),
        ],
      ),
    );
  }

  // ── Notif panel ───────────────────────────────────────────────────────────
  Widget _buildNotifPanel() {
    final recent = _reports.take(3).toList();

    String _pesanNotif(ReportItem r) => switch (r.status) {
      'proses'  => 'Laporan "${r.title}" sedang diproses.',
      'selesai' => 'Laporan "${r.title}" telah selesai diperbaiki.',
      _         => 'Laporan "${r.title}" berhasil dikirim, menunggu verifikasi.',
    };

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notifikasi',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          if (recent.isEmpty)
            const Text(
              'Tidak ada notifikasi.',
              style: TextStyle(color: kTextDim, fontSize: 12),
            )
          else
            ...recent.map((r) => _NotifItem(
              pesan: _pesanNotif(r),
              waktu: r.tanggal,
              dibaca: r.status == 'selesai',
            )),
        ],
      ),
    );
  }

  // ── Two-col layout ────────────────────────────────────────────────────────
  Widget _buildTwoCol(Widget left, Widget right) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: LayoutBuilder(
      builder: (_, c) {
        if (c.maxWidth < 360) {
          return Column(children: [left, const SizedBox(height: 10), right]);
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: left),
              const SizedBox(width: 10),
              Expanded(child: right),
            ],
          ),
        );
      },
    ),
  );
}

// ── Stat Card ─────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value, sub;
  final Color valueColor;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kNavy2,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: kTextDim, size: 13),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: kTextDim,
                  fontSize: 10,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(sub, style: const TextStyle(color: kTextDim, fontSize: 10)),
      ],
    ),
  );
}

// ── Laporan Card ──────────────────────────────────────────────────────────
class _LaporanCard extends StatelessWidget {
  final ReportItem report;
  const _LaporanCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor, iconBg) = statusIconStyle(report.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kNavy2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: kTextDim, size: 11),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        '${report.address}  ·  ${report.tanggal}',
                        style: const TextStyle(color: kTextDim, fontSize: 11),
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
    );
  }
}

// ── Map Painter ───────────────────────────────────────────────────────────
class _MapPainter extends CustomPainter {
  final List<ReportItem> reports;
  const _MapPainter({required this.reports});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 0.5;

    for (double y = size.height / 3; y < size.height; y += size.height / 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = size.width / 4; x < size.width; x += size.width / 4) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    if (reports.isEmpty) return;

    final lats   = reports.map((r) => r.latitude!).toList();
    final lngs   = reports.map((r) => r.longitude!).toList();
    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLng = lngs.reduce((a, b) => a < b ? a : b);
    final maxLng = lngs.reduce((a, b) => a > b ? a : b);
    final dLat   = (maxLat - minLat).abs() < 0.0001 ? 1.0 : maxLat - minLat;
    final dLng   = (maxLng - minLng).abs() < 0.0001 ? 1.0 : maxLng - minLng;

    const pad = 12.0;
    for (final r in reports) {
      final x = pad + ((r.longitude! - minLng) / dLng) * (size.width  - pad * 2);
      final y = pad + (1 - (r.latitude! - minLat) / dLat) * (size.height - pad * 2);
      final dot = Offset(x, y);
      canvas.drawCircle(dot, 8, Paint()..color = kBlueBright.withOpacity(0.2));
      canvas.drawCircle(dot, 4, Paint()..color = kBlueBright);
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.reports != reports;
}

// ── Timeline Item ─────────────────────────────────────────────────────────
class _TimelineItem extends StatelessWidget {
  final String label;
  final bool done;
  const _TimelineItem({required this.label, required this.done});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: done
              ? Container(
                  width: 10, height: 10,
                  decoration: const BoxDecoration(
                    color: kBlueTag,
                    shape: BoxShape.circle,
                  ),
                )
              : Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kBorder, width: 2),
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: done ? Colors.white : kTextDim,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

// ── Status Bar ────────────────────────────────────────────────────────────
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
          Text(label, style: const TextStyle(color: kTextMuted, fontSize: 11)),
          Text(count, style: const TextStyle(color: kTextMuted, fontSize: 11)),
        ],
      ),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: ratio.clamp(0.0, 1.0),
          minHeight: 5,
          backgroundColor: Colors.white.withOpacity(0.08),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    ],
  );
}

// ── Notif Item ────────────────────────────────────────────────────────────
class _NotifItem extends StatelessWidget {
  final String pesan, waktu;
  final bool dibaca;
  const _NotifItem({
    required this.pesan,
    required this.waktu,
    this.dibaca = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: kBorder, width: 0.5)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            width: 7, height: 7,
            decoration: BoxDecoration(
              color: dibaca ? Colors.transparent : kBlueBright,
              shape: BoxShape.circle,
              border: dibaca ? Border.all(color: kBorder) : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pesan,
                style: TextStyle(
                  color: dibaca ? kTextDim : Colors.white,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(waktu, style: const TextStyle(color: kTextDim, fontSize: 10)),
            ],
          ),
        ),
      ],
    ),
  );
}

// ── Tips Section ──────────────────────────────────────────────────────────
class _TipsSection extends StatelessWidget {
  const _TipsSection();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tips pelaporan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        _TipItem(
          icon: Icons.camera_alt_outlined,
          title: 'Upload foto yang jelas',
          desc: 'Foto dari dekat dan jauh membantu admin memverifikasi laporan lebih cepat.',
        ),
        _TipItem(
          icon: Icons.location_on_outlined,
          title: 'Aktifkan GPS saat melapor',
          desc: 'Koordinat yang akurat membantu pekerja menemukan lokasi dengan tepat.',
        ),
        _TipItem(
          icon: Icons.description_outlined,
          title: 'Deskripsikan kerusakan dengan detail',
          desc: 'Sebutkan panjang, kedalaman, dan risiko yang ditimbulkan.',
        ),
      ],
    ),
  );
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String title, desc;
  const _TipItem({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: kNavy2,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: kBlueBright, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(color: kTextDim, fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}