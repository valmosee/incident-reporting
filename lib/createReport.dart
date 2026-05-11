import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class CreateReport extends StatefulWidget {
  const CreateReport({super.key});

  @override
  State<CreateReport> createState() => _CreateReportState();
}

class _CreateReportState extends State<CreateReport> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  FilePickerResult? _resultFile;
  String? _selectedJenis;
  double? _lat;
  double? _lng;
  bool _loadingLocation = false;
  bool _submitting = false;

  Future<void> _pilihFile() async {
    if (kIsWeb) {
      // WEB: file_picker biasa, withData: true wajib karena tidak ada path
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        withData: true,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov', 'avi'],
      );
      if (result == null || result.files.isEmpty) return;
      setState(() => _resultFile = result);
    } else if (Platform.isAndroid || Platform.isIOS) {
      // MOBILE: bisa pakai path atau bytes
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        withData: false,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov', 'avi'],
      );
      if (result == null || result.files.isEmpty) return;
      setState(() => _resultFile = result);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _loadingLocation = true);

    // TODO: implement geolocator
    try {
      // 1. Cek apakah location service aktif
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aktifkan GPS / Location Service terlebih dahulu'),
            ),
          );
        }
        return;
      }

      // 2. Cek & minta permission (berbeda behavior per platform)
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin lokasi ditolak')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Izin lokasi diblokir permanen. Buka pengaturan untuk mengaktifkan.',
              ),
              action: SnackBarAction(
                label: 'Buka',
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
        }
        return;
      }

      // 3. Ambil posisi — setting akurasi berbeda per platform
      Position position;

      if (kIsWeb) {
        // WEB: tidak support high accuracy terlalu sering, pakai best effort
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          ),
        );
      } else if (Platform.isAndroid) {
        // ANDROID: bisa pakai AndroidSettings dengan forceLocationManager
        position = await Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.high,
            forceLocationManager:
                false, // pakai FusedLocationProvider (lebih akurat)
            timeLimit: const Duration(seconds: 5),
          ),
        );
      } else if (Platform.isIOS) {
        // IOS: pakai AppleSettings dengan activityType
        position = await Geolocator.getCurrentPosition(
          locationSettings: AppleSettings(
            accuracy: LocationAccuracy.high,
            activityType: ActivityType.other,
            timeLimit: const Duration(seconds: 5),
            pauseLocationUpdatesAutomatically: false,
          ),
        );
      } else {
        // Fallback platform lain (desktop, dll)
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        );
      }

      _lat = position.latitude;
      _lng = position.longitude;

      // 4. Reverse geocoding — web tidak support geocoding package,
      //    pakai koordinat langsung sebagai fallback
      if (kIsWeb) {
        _addressCtrl.text =
            '${position.latitude.toStringAsFixed(5)}, '
            '${position.longitude.toStringAsFixed(5)}';
      } else {
        // Android & iOS: reverse geocode ke alamat
        try {
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );

          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final parts = [
              p.street,
              p.subLocality,
              p.locality,
              p.subAdministrativeArea,
            ].where((e) => e != null && e.isNotEmpty).join(', ');

            _addressCtrl.text = parts.isNotEmpty
                ? parts
                : '${position.latitude}, ${position.longitude}';
          }
        } catch (e) {
          // Geocoding gagal, fallback ke koordinat — lat/lng tetap tersimpan
          _addressCtrl.text = '${position.latitude}, ${position.longitude}';
        }
      }

      // setState hanya untuk rebuild UI
      if (mounted) setState(() {});
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Timeout: GPS terlalu lama merespons')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mendapatkan lokasi: $e')));
      }
    } finally {
      setState(() => _loadingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul laporan wajib diisi')),
      );
      return;
    }
    setState(() => _submitting = true);

    try {
      // Upload semua file ke Supabase storage
      final List<String> uploadedUrls = [];
      if (_resultFile != null) {
        for (final pickedFile in _resultFile!.files) {
          // nama file
          final fileName =
              DateTime.now().millisecondsSinceEpoch.toString() +
              "." +
              pickedFile.extension.toString();

          if (kIsWeb) {
            // WEB: wajib pakai bytes
            final bytes = pickedFile.bytes;
            if (bytes == null) continue;

            await Supabase.instance.client.storage
                .from('event_report')
                .uploadBinary(fileName, bytes);
          } else if (Platform.isAndroid || Platform.isIOS) {
            // MOBILE: bisa pakai path
            final path = pickedFile.path;
            if (path == null) continue;

            final file = File(path);
            await Supabase.instance.client.storage
                .from('event_report')
                .upload(fileName, file);
          }

          final url = Supabase.instance.client.storage
              .from('event_report')
              .getPublicUrl(fileName);
          uploadedUrls.add(url);
        }
      }

      // TODO: simpan ke tabel reports
      await Supabase.instance.client.from('reports').insert({
        'title': _titleCtrl.text,
        'description': _descCtrl.text,
        'jenis': _selectedJenis ?? 'kerusakan',
        'address': _addressCtrl.text,
        'latitude': _lat,
        'longitude': _lng,
        'file_url': uploadedUrls.join(','),
        'status': 'pending',
        'qr_code': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan berhasil dikirim!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengirim laporan: $e')));
      }
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final files = _resultFile?.files ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Buat Laporan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Upload Foto / Video ────────────────────────
            _buildLabel('Foto / Video'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pilihFile,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 120),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2D42),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: files.isEmpty
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.perm_media_outlined,
                            size: 40,
                            color: Colors.white38,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Ketuk untuk pilih foto/video',
                            style: TextStyle(color: Colors.white38),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Bisa pilih lebih dari 1 file',
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Preview grid thumbnail nama file
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: files.map((f) {
                              final isVideo = [
                                'mp4',
                                'mov',
                                'avi',
                              ].contains(f.extension?.toLowerCase());
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D1B2A),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isVideo
                                          ? Icons.videocam_outlined
                                          : Icons.image_outlined,
                                      color: Colors.white54,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 120,
                                      ),
                                      child: Text(
                                        f.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                          // Tombol ganti file
                          GestureDetector(
                            onTap: _pilihFile,
                            child: const Text(
                              'Ganti file',
                              style: TextStyle(
                                color: Color(0xFF4D9EFF),
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Judul ─────────────────────────────────────
            _buildLabel('Judul Laporan'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _titleCtrl,
              hint: 'Contoh: Jalan rusak di...',
            ),
            const SizedBox(height: 16),

            // ── Jenis Incident ─────────────────────────────
            _buildLabel('Jenis Incident'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedJenis,
              dropdownColor: const Color(0xFF1A2D42),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Pilih jenis incident...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1A2D42),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'kerusakan', child: Text('Kerusakan')),
                DropdownMenuItem(
                  value: 'kecelakaan',
                  child: Text('Kecelakaan'),
                ),
                DropdownMenuItem(
                  value: 'kriminal',
                  child: Text('Kriminalitas'),
                ),
                DropdownMenuItem(value: 'lainnya', child: Text('Lainnya')),
              ],
              onChanged: (value) => setState(() => _selectedJenis = value),
            ),
            const SizedBox(height: 16),

            // ── Deskripsi ─────────────────────────────────
            _buildLabel('Deskripsi Kerusakan'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _descCtrl,
              hint: 'Jelaskan kondisi jalan...',
              maxLines: 4,
            ),
            const SizedBox(height: 20),

            // ── Lokasi ────────────────────────────────────
            _buildLabel('Lokasi'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _addressCtrl,
                    hint: 'Cari alamat...',
                  ),
                ),
                const SizedBox(width: 10),
                _loadingLocation
                    ? const SizedBox(
                        width: 50,
                        height: 50,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: _getCurrentLocation,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.my_location_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Kirim ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  disabledBackgroundColor: const Color(
                    0xFF1565C0,
                  ).withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Kirim Laporan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String? hint,
    String? initialValue,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      maxLines: maxLines,
      readOnly: readOnly,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF1A2D42),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
        ),
      ),
    );
  }
}
