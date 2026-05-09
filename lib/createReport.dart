import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      withData: true,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov', 'avi'],
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _resultFile = result);
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _loadingLocation = true);
    // TODO: implement geolocator
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _lat = -7.2937;
      _lng = 112.7313;
      _addressCtrl.text = 'Jl. Contoh No. 1';
      _loadingLocation = false;
    });
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
          final bytes = pickedFile.bytes;
          if (bytes == null) continue;

          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';

          await Supabase.instance.client.storage
              .from('event_report')
              .uploadBinary(fileName, bytes);

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

      await Future.delayed(const Duration(seconds: 1));

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
