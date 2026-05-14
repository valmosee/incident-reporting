import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'showMap.dart';
import 'global.dart' as global;

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
  bool _submitting = false;

  Future<void> _pilihFile() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        withData: true,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov', 'avi'],
      );
      if (result == null || result.files.isEmpty) return;
      setState(() => _resultFile = result);
    } else if (Platform.isAndroid || Platform.isIOS) {
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

  // ── Buka halaman peta, tunggu hasil pilihan ───────────────────────────────
  void _pilihlokasi() async {
    // Reset global sebelum buka peta
    global.lokasi = '';
    global.latitude = 0;
    global.longitude = 0;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Showmap()),
    );

    // Setelah kembali dari peta, ambil alamat dari global
    if (global.lokasi.isNotEmpty) {
      setState(() {
        _addressCtrl.text = global.lokasi;
      });
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
      final List<String> uploadedUrls = [];
      if (_resultFile != null) {
        for (final pickedFile in _resultFile!.files) {
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}.${pickedFile.extension}';

          if (kIsWeb) {
            final bytes = pickedFile.bytes;
            if (bytes == null) continue;
            await Supabase.instance.client.storage
                .from('event_report')
                .uploadBinary(fileName, bytes);
          } else if (Platform.isAndroid || Platform.isIOS) {
            final path = pickedFile.path;
            if (path == null) continue;
            await Supabase.instance.client.storage
                .from('event_report')
                .upload(fileName, File(path));
          }

          final url = Supabase.instance.client.storage
              .from('event_report')
              .getPublicUrl(fileName);
          uploadedUrls.add(url);
        }
      }

      await Supabase.instance.client.from('reports').insert({
        'title': _titleCtrl.text,
        'description': _descCtrl.text,
        'jenis': _selectedJenis ?? 'kerusakan',
        'address': _addressCtrl.text,
        'latitude': global.latitude,
        'longitude': global.longitude,
        'file_url': uploadedUrls.join(','),
        'status': 'pending',
        'qr_code': null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan berhasil dikirim!')),
        );
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengirim laporan: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
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
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D1B2A),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isVideo
                                          ? Icons.videocam_outlined
                                          : Icons.image_outlined,
                                      color: Colors.white54,
                                      size: 28,
                                    ),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Text(
                                        f.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
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
                    hint: 'Ketuk ikon peta untuk pilih lokasi...',
                    readOnly: true, // readonly: diisi dari peta
                  ),
                ),
                const SizedBox(width: 10),
                // ← Tombol ini buka halaman showMap
                GestureDetector(
                  onTap: _pilihlokasi,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.map_outlined, color: Colors.white),
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
