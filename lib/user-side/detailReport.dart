// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../showMap.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────
class DetailReportItem {
  final int id;
  final String title;
  final String address;
  final String tanggal;
  final String status;
  final String jenis;
  final List<String> fileUrls;
  final double? latitude;
  final double? longitude;

  const DetailReportItem({
    required this.id,
    required this.title,
    required this.address,
    required this.tanggal,
    required this.status,
    required this.jenis,
    this.fileUrls = const [],
    this.latitude,
    this.longitude,
  });

  factory DetailReportItem.fromMap(Map<String, dynamic> m, String tanggalFmt) {
    final raw = m['file_url'] as String? ?? '';
    final urls = raw.isNotEmpty
        ? raw
              .split(',')
              .map((u) => u.trim())
              .where((u) => u.isNotEmpty)
              .toList()
        : <String>[];
    return DetailReportItem(
      id: m['id'] as int,
      title: m['title'] as String? ?? '(tanpa judul)',
      address: m['address'] as String? ?? '-',
      tanggal: tanggalFmt,
      status: m['status'] as String? ?? 'pending',
      jenis: m['jenis'] as String? ?? 'kerusakan',
      fileUrls: urls,
      latitude: (m['latitude'] as num?)?.toDouble(),
      longitude: (m['longitude'] as num?)?.toDouble(),
    );
  }

  bool get hasLocation =>
      latitude != null && longitude != null && latitude != 0 && longitude != 0;

  LatLng? get latLng => hasLocation ? LatLng(latitude!, longitude!) : null;

  String get shareUrl => 'https://192.168.18.18:61236/reports/$id';
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL REPORT PAGE
// ─────────────────────────────────────────────────────────────────────────────
class DetailReportPage extends StatefulWidget {
  final DetailReportItem? item;
  final int? reportId;

  const DetailReportPage({super.key, this.item, this.reportId})
    : assert(
        item != null || reportId != null,
        'Provide either item or reportId',
      );

  @override
  State<DetailReportPage> createState() => _DetailReportPageState();
}

class _DetailReportPageState extends State<DetailReportPage> {
  final _db = Supabase.instance.client;

  DetailReportItem? _item;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.reportId != null) {
      // Selalu fetch dari Supabase supaya lat/lng dan file_url selalu fresh
      _fetchById(widget.reportId!);
    } else if (widget.item != null) {
      _item = widget.item;
      // Fetch ulang supaya koordinat tidak stale
      _fetchById(widget.item!.id);
    }
  }

  Future<void> _fetchById(int id) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final row = await _db.from('reports').select().eq('id', id).single();
      String fmt = '';
      try {
        final dt = DateTime.parse(row['created_at'] as String);
        fmt = _fmtDate(dt);
      } catch (_) {
        fmt = row['tanggal']?.toString() ?? '';
      }
      setState(() {
        _item = DetailReportItem.fromMap(row, fmt);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _fmtDate(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final l = dt.toLocal();
    return '${l.day} ${months[l.month]} ${l.year}, '
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  void _showShareDialog(DetailReportItem item) {
    showDialog(
      context: context,
      builder: (_) => _ShareQrDialog(item: item),
    );
  }

  void _openMap(LatLng pos) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Showmap(initialLatLng: pos, viewOnly: true),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      appBar: _buildAppBar(),
      body: _loading
          ? const LoadingCenter()
          : _error != null
          ? ErrorCenter(
              message: _error!,
              onRetry: () => _fetchById(widget.reportId!),
            )
          : _item == null
          ? const Center(
              child: Text(
                'Data tidak ditemukan.',
                style: TextStyle(color: kTextMuted),
              ),
            )
          : _buildBody(_item!),
    );
  }

  AppBar _buildAppBar() => AppBar(
    backgroundColor: kNavy,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => Navigator.maybePop(context),
    ),
    title: const Text(
      'Detail Laporan',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
    ),
    actions: [
      if (_item != null)
        IconButton(
          tooltip: 'Bagikan laporan',
          icon: const Icon(Icons.share_outlined, color: kBlueBright),
          onPressed: () => _showShareDialog(_item!),
        ),
      const SizedBox(width: 4),
    ],
  );

  Widget _buildBody(DetailReportItem item) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title & status ───────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              StatusBadge(status: item.status),
            ],
          ),
          const SizedBox(height: 8),
          JenisBadge(jenis: item.jenis),
          const SizedBox(height: 24),

          // ── Info rows ────────────────────────────────────────────────────
          AppCard(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.tag,
                  label: 'ID Laporan',
                  value: '#${item.id}',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: kBorder, height: 1),
                ),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Lokasi',
                  value: item.address,
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: kBorder, height: 1),
                ),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Dilaporkan',
                  value: item.tanggal,
                ),
              ],
            ),
          ),

          // ── Peta + Progress berdampingan ─────────────────────────────────
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Kiri: peta mini (atau placeholder kalau tidak ada koordinat)
                Expanded(
                  flex: 5,
                  child: item.hasLocation
                      ? _MapPreview(
                          latLng: item.latLng!,
                          label: item.address,
                          onTap: () => _openMap(item.latLng!),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: kNavy2,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: kBorder),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_off_outlined,
                                color: kTextDim,
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Koordinat\ntidak tersedia',
                                style: kStyleDim,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                // Kanan: progress timeline
                Expanded(
                  flex: 4,
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Progress',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _FullTimeline(status: item.status),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Media (foto / video) ─────────────────────────────────────────
          if (item.fileUrls.isNotEmpty) ...[
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Bukti Laporan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: kBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${item.fileUrls.length} file',
                          style: const TextStyle(
                            color: kBlueBright,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _MediaGrid(urls: item.fileUrls),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAP PREVIEW — kotak peta kecil, tap buka Showmap viewOnly
// ─────────────────────────────────────────────────────────────────────────────
class _MapPreview extends StatelessWidget {
  final LatLng latLng;
  final String label;
  final VoidCallback onTap;

  const _MapPreview({
    required this.latLng,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: kNavy3,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // ── Peta non-interaktif ──────────────────────────────────────
            IgnorePointer(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: latLng,
                  initialZoom: 16,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none, // tidak bisa di-drag / zoom
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.jalankita.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: latLng,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Overlay label + "buka peta" ──────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.75),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Buka peta ↗',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MEDIA GRID
// ─────────────────────────────────────────────────────────────────────────────
class _MediaGrid extends StatelessWidget {
  final List<String> urls;
  const _MediaGrid({required this.urls});

  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.avi');
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: urls.length,
      itemBuilder: (ctx, i) {
        final url = urls[i];
        if (_isVideo(url)) {
          return _VideoThumb(url: url, onTap: () => _openFullscreen(ctx, i));
        }
        return _PhotoThumb(url: url, onTap: () => _openFullscreen(ctx, i));
      },
    );
  }

  void _openFullscreen(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _FullscreenMediaViewer(urls: urls, initialIndex: initialIndex),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final String url;
  final VoidCallback onTap;
  const _PhotoThumb({required this.url, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                color: kNavy3,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(
                  color: kBlueBright,
                  strokeWidth: 2,
                ),
              ),
        errorBuilder: (_, __, ___) => Container(
          color: kNavy3,
          alignment: Alignment.center,
          child: const Icon(
            Icons.broken_image_outlined,
            color: kTextDim,
            size: 28,
          ),
        ),
      ),
    ),
  );
}

class _VideoThumb extends StatelessWidget {
  final String url;
  final VoidCallback onTap;
  const _VideoThumb({required this.url, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        color: kNavy3,
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.videocam_outlined, color: kTextDim, size: 32),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kBlue.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// FULLSCREEN MEDIA VIEWER
// ─────────────────────────────────────────────────────────────────────────────
class _FullscreenMediaViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  const _FullscreenMediaViewer({
    required this.urls,
    required this.initialIndex,
  });

  @override
  State<_FullscreenMediaViewer> createState() => _FullscreenMediaViewerState();
}

class _FullscreenMediaViewerState extends State<_FullscreenMediaViewer> {
  late final PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_current + 1} / ${widget.urls.length}',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          child: Center(
            child: Image.network(
              widget.urls[i],
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 64,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FULL TIMELINE
// ─────────────────────────────────────────────────────────────────────────────
class _FullTimeline extends StatelessWidget {
  final String status;
  const _FullTimeline({required this.status});

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
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
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
                              size: 13,
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
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
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
                        style: const TextStyle(
                          color: kTextDim,
                          fontSize: 11,
                          height: 1.4,
                        ),
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

// ─────────────────────────────────────────────────────────────────────────────
// INFO ROW
// ─────────────────────────────────────────────────────────────────────────────
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
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(9),
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
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARE / QR DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _ShareQrDialog extends StatelessWidget {
  final DetailReportItem item;
  const _ShareQrDialog({required this.item});

  @override
  Widget build(BuildContext context) {
    final url = item.shareUrl;

    return Dialog(
      backgroundColor: kNavy2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Bagikan Laporan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: kTextMuted, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: kTextMuted, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // QR code
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: QrImageView(
                data: url,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Scan QR atau salin tautan di bawah',
              style: TextStyle(color: kTextDim, fontSize: 11),
            ),
            const SizedBox(height: 16),

            // URL row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: kNavy3,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      url,
                      style: const TextStyle(color: kBlueBright, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tautan disalin!'),
                          backgroundColor: kNavy2,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.copy_outlined,
                      color: kBlueBright,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
