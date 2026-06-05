// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────
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

const _filterOptions = ['Semua', 'Menunggu', 'Diproses', 'Selesai'];

// ─────────────────────────────────────────────────────────────────────────────
// HISTORY REPORT PAGE
// ─────────────────────────────────────────────────────────────────────────────
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

  // ── Fetch ──────────────────────────────────────────────────────────────────
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

  // ── Filter + Search ────────────────────────────────────────────────────────
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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      appBar: AppBar(
        backgroundColor: kNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
            onPressed: _fetchReports,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: kInputDecoration(
                hint: 'Cari judul, lokasi, atau jenis...',
                prefix: const Icon(Icons.search, color: kTextDim, size: 20),
                suffix: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close,
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
          ),

          // ── Filter chips ─────────────────────────────────────────────────
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
          const SizedBox(height: 12),

          // ── Summary count ────────────────────────────────────────────────
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Text(
                    '${_filtered.length} laporan ditemukan',
                    style: kStyleDim,
                  ),
                ],
              ),
            ),

          // ── List ─────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const LoadingCenter()
                : _error != null
                ? ErrorCenter(message: _error!, onRetry: _fetchReports)
                : _filtered.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: _fetchReports,
                    color: kBlueBright,
                    backgroundColor: kNavy2,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    final hasActiveFilter =
        _searchCtrl.text.isNotEmpty || _activeFilter != 'Semua';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasActiveFilter ? Icons.search_off_rounded : Icons.inbox_outlined,
            color: kTextDim,
            size: 56,
          ),
          const SizedBox(height: 12),
          Text(
            hasActiveFilter
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
            hasActiveFilter
                ? 'Coba ubah filter atau kata kunci pencarian'
                : 'Tap tombol di bawah untuk membuat laporan pertama',
            style: kStyleDim,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Bottom sheet detail ────────────────────────────────────────────────────
  void _showDetail(HistoryItem item) {
    Navigator.pushNamed(context, '/detailReport', arguments: item.id);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HISTORY CARD
// ─────────────────────────────────────────────────────────────────────────────
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
        decoration: kCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row atas
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
                        style: kStyleCardTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      JenisBadge(jenis: item.jenis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: item.status),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: kBorder, height: 1),
            ),

            // Row bawah
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
                    style: kStyleDim,
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
                Text(item.tanggal, style: kStyleDim),
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
