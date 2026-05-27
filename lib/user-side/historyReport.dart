// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_colors.dart';
import '../app_widgets.dart';

// ── Model ─────────────────────────────────────────────────────────────────
class HistoryItem {
  final int id;
  final String title;
  final String address;
  final String tanggal;
  final String status;
  final String jenis;
  final String fileUrl;

  const HistoryItem({
    required this.id,
    required this.title,
    required this.address,
    required this.tanggal,
    required this.status,
    required this.jenis,
    this.fileUrl = '',
  });

  factory HistoryItem.fromMap(Map<String, dynamic> m) {
    String fmt = '';
    try {
      final dt = DateTime.parse(m['created_at'] as String);
      fmt = DateFormat('d MMM yyyy, HH:mm', 'id').format(dt.toLocal());
    } catch (_) {
      fmt = m['tanggal']?.toString() ?? '';
    }
    return HistoryItem(
      id: m['id'] as int,
      title: m['title'] as String? ?? '(tanpa judul)',
      address: m['address'] as String? ?? '-',
      tanggal: fmt,
      status: m['status'] as String? ?? 'pending',
      jenis: m['jenis'] as String? ?? 'kerusakan',
      fileUrl: m['file_url'] as String? ?? '',
    );
  }
}

// ── Konstanta filter ──────────────────────────────────────────────────────
const _filterOptions = ['Semua', 'Menunggu', 'Diproses', 'Selesai'];

// ── HistoryReport ─────────────────────────────────────────────────────────
class HistoryReport extends StatefulWidget {
  const HistoryReport({super.key});

  @override
  State<HistoryReport> createState() => _HistoryReportState();
}

class _HistoryReportState extends State<HistoryReport> {
  final _db = Supabase.instance.client;
  final _searchCtrl = TextEditingController();

  List<HistoryItem> _all = [];
  List<HistoryItem> _filtered = [];
  String _activeFilter = 'Semua';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchReports();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────
  Future<void> _fetchReports() async {
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

      final rows = await _db
          .from('reports')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _all = (rows as List).map((r) => HistoryItem.fromMap(r)).toList();
        _loading = false;
      });
      _applyFilter();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ── Filter + Search ───────────────────────────────────────────────────────
  void _applyFilter() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _all.where((r) {
        final matchFilter =
            _activeFilter == 'Semua' ||
            (_activeFilter == 'Menunggu' && r.status == 'pending') ||
            (_activeFilter == 'Diproses' && r.status == 'proses') ||
            (_activeFilter == 'Selesai' && r.status == 'selesai');
        final matchSearch =
            query.isEmpty ||
            r.title.toLowerCase().contains(query) ||
            r.address.toLowerCase().contains(query) ||
            r.jenis.toLowerCase().contains(query);
        return matchFilter && matchSearch;
      }).toList();
    });
  }

  void _setFilter(String f) {
    setState(() => _activeFilter = f);
    _applyFilter();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      appBar: AppBar(
        backgroundColor: kNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Riwayat Laporan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kTextMuted),
            tooltip: 'Muat ulang',
            onPressed: _fetchReports,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: AppTextField(
              controller: _searchCtrl,
              hintText: 'Cari judul, lokasi, atau jenis...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: kTextDim,
                size: 20,
              ),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: kTextDim,
                        size: 18,
                      ),
                      onPressed: () {
                        _searchCtrl.clear();
                        _applyFilter();
                      },
                    )
                  : null,
            ),
          ),

          // ── Filter chips ───────────────────────────────────────────────
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filterOptions[i];
                final active = _activeFilter == f;
                return GestureDetector(
                  onTap: () => _setFilter(f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: active ? kBlue : kNavy2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? kBlue : kBorder,
                        width: 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (active) ...[
                          const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          f,
                          style: TextStyle(
                            color: active ? Colors.white : kTextMuted,
                            fontSize: 12,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Summary count ──────────────────────────────────────────────
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              child: Row(
                children: [
                  Text(
                    '${_filtered.length} laporan ditemukan',
                    style: const TextStyle(color: kTextDim, fontSize: 12),
                  ),
                ],
              ),
            ),

          // ── List ───────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: kBlueBright),
                  )
                : _error != null
                ? _buildError()
                : _filtered.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: _fetchReports,
                    color: kBlueBright,
                    backgroundColor: kNavy2,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _HistoryCard(
                        item: _filtered[i],
                        onTap: () => _showDetail(_filtered[i]),
                      ),
                    ),
                  ),
          ),
        ],
      ),

      // ── FAB buat laporan baru ──────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/createReport');
          _fetchReports();
        },
        backgroundColor: kBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Buat Laporan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── Error & empty states ──────────────────────────────────────────────────
  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: kRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.error_outline_rounded,
              color: kRed,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(color: kTextMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Coba lagi', onPressed: _fetchReports),
        ],
      ),
    ),
  );

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: kNavy2,
              shape: BoxShape.circle,
              border: Border.all(color: kBorder),
            ),
            alignment: Alignment.center,
            child: Icon(
              _searchCtrl.text.isNotEmpty || _activeFilter != 'Semua'
                  ? Icons.search_off_rounded
                  : Icons.inbox_outlined,
              color: kTextDim,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchCtrl.text.isNotEmpty || _activeFilter != 'Semua'
                ? 'Tidak ada laporan yang cocok'
                : 'Belum ada laporan',
            style: const TextStyle(
              color: kTextMuted,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _searchCtrl.text.isNotEmpty || _activeFilter != 'Semua'
                ? 'Coba ubah filter atau kata kunci pencarian'
                : 'Tap tombol di bawah untuk membuat laporan pertama',
            style: const TextStyle(color: kTextDim, fontSize: 12, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  // ── Bottom sheet detail ────────────────────────────────────────────────────
  void _showDetail(HistoryItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kNavy2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => _DetailSheet(item: item),
    );
  }
}

// ── History Card ──────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final HistoryItem item;
  final VoidCallback onTap;
  const _HistoryCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor, iconBg) = statusIconStyle(item.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kNavy2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row atas: icon + judul + badge ─────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
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
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      JenisBadge(jenis: item.jenis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: item.status),
              ],
            ),

            // ── Divider ────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: kBorder, height: 1),
            ),

            // ── Row bawah: lokasi + tanggal + panah ────────────────────
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: kTextDim,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.address,
                    style: const TextStyle(color: kTextDim, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.calendar_today_outlined,
                  color: kTextDim,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  item.tanggal,
                  style: const TextStyle(color: kTextDim, fontSize: 11),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: kTextDim, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detail Bottom Sheet ───────────────────────────────────────────────────
class _DetailSheet extends StatelessWidget {
  final HistoryItem item;
  const _DetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final photos = item.fileUrl.isEmpty
        ? <String>[]
        : item.fileUrl.split(',').where((u) => u.trim().isNotEmpty).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kBorder,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ────────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      StatusBadge(status: item.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  JenisBadge(jenis: item.jenis),
                  const SizedBox(height: 20),

                  // ── Info rows ─────────────────────────────────────────
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Lokasi',
                    value: item.address,
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Dilaporkan',
                    value: item.tanggal,
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.tag,
                    label: 'ID Laporan',
                    value: '#${item.id}',
                  ),

                  // ── Timeline ──────────────────────────────────────────
                  const SizedBox(height: 24),
                  const Text(
                    'Progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SheetTimeline(status: item.status),

                  // ── Foto bukti ────────────────────────────────────────
                  if (photos.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Foto Bukti',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: photos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            photos[i].trim(),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 100,
                              height: 100,
                              color: kNavy,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: kTextDim,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
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
            Text(label, style: const TextStyle(color: kTextDim, fontSize: 11)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    ],
  );
}

// ── Sheet Timeline ────────────────────────────────────────────────────────
class _SheetTimeline extends StatelessWidget {
  final String status;
  const _SheetTimeline({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {
        'label': 'Laporan Dikirim',
        'sub': 'Laporan berhasil masuk ke sistem',
        'done': true,
      },
      {
        'label': 'Verifikasi Admin',
        'sub': 'Admin sedang memeriksa laporan',
        'done': status == 'proses' || status == 'selesai',
      },
      {
        'label': 'Pekerja Ditugaskan',
        'sub': 'Tim lapangan diarahkan ke lokasi',
        'done': status == 'proses' || status == 'selesai',
      },
      {
        'label': 'Perbaikan Selesai',
        'sub': 'Kerusakan telah berhasil diperbaiki',
        'done': status == 'selesai',
      },
    ];

    return Column(
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final done = step['done'] as bool;
        final isLast = i == steps.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dot + connector line
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: done ? kBlueTag : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: done ? kBlueTag : kBorder,
                          width: done ? 0 : 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: done
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            )
                          : null,
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: done ? kBlueTag.withOpacity(0.4) : kBorder,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Text
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['label'] as String,
                        style: TextStyle(
                          color: done ? Colors.white : kTextDim,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step['sub'] as String,
                        style: const TextStyle(color: kTextDim, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
