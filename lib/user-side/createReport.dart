import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../showMap.dart';
import '../global.dart' as global;
import '../app_colors.dart';
import '../app_widgets.dart';

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

  // ── Pilih file ────────────────────────────────────────────────────────────
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

  // ── Pilih lokasi via peta ──────────────────────────────────────────────────
  void _pilihlokasi() async {
    global.lokasi = '';
    global.latitude = 0;
    global.longitude = 0;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Showmap()),
    );

    if (global.lokasi.isNotEmpty) {
      setState(() => _addressCtrl.text = global.lokasi);
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────
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
        'user_id': Supabase.instance.client.auth.currentUser!.id,
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

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final files = _resultFile?.files ?? [];

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
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Buat Laporan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Upload Foto / Video ───────────────────────────────────────
            const FormLabel('Foto / Video'),
            const SizedBox(height: 8),
            _UploadArea(files: files, onTap: _pilihFile),
            const SizedBox(height: 24),

            // ── Judul ─────────────────────────────────────────────────────
            const FormLabel('Judul Laporan'),
            const SizedBox(height: 8),
            AppTextField(
              controller: _titleCtrl,
              hintText: 'Contoh: Jalan rusak di Jl. Merdeka...',
            ),
            const SizedBox(height: 20),

            // ── Jenis Incident ────────────────────────────────────────────
            const FormLabel('Jenis Incident'),
            const SizedBox(height: 8),
            _JenisDropdown(
              value: _selectedJenis,
              onChanged: (v) => setState(() => _selectedJenis = v),
            ),
            const SizedBox(height: 20),

            // ── Deskripsi ─────────────────────────────────────────────────
            const FormLabel('Deskripsi Kerusakan'),
            const SizedBox(height: 8),
            AppTextField(
              controller: _descCtrl,
              hintText: 'Jelaskan kondisi, panjang, kedalaman, risiko...',
              maxLines: 4,
            ),
            const SizedBox(height: 20),

            // ── Lokasi ────────────────────────────────────────────────────
            const FormLabel('Lokasi'),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _addressCtrl,
                    hintText: 'Ketuk ikon peta untuk pilih lokasi...',
                    readOnly: true,
                    prefixIcon: const Icon(
                      Icons.location_on_outlined,
                      color: kTextDim,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _MapPickerBtn(onTap: _pilihlokasi),
              ],
            ),
            const SizedBox(height: 28),

            // ── Kirim ─────────────────────────────────────────────────────
            PrimaryButton(
              label: 'Kirim Laporan',
              icon: Icons.send_rounded,
              loading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Upload Area ───────────────────────────────────────────────────────────
class _UploadArea extends StatelessWidget {
  final List<PlatformFile> files;
  final VoidCallback onTap;
  const _UploadArea({required this.files, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 130),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kNavy2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: files.isEmpty ? kBorder : kBlueBright.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: files.isEmpty ? _emptyState() : _filledState(context),
      ),
    );
  }

  Widget _emptyState() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: kBlueBright.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.perm_media_outlined,
          size: 24,
          color: kBlueBright,
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        'Ketuk untuk pilih foto / video',
        style: TextStyle(
          color: kTextMuted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'JPG, PNG, MP4 · Bisa lebih dari 1 file',
        style: TextStyle(color: kTextDim, fontSize: 11),
      ),
    ],
  );

  Widget _filledState(BuildContext context) => Column(
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
              color: kNavy,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBorder),
            ),
            alignment: Alignment.center,
            child: isVideo
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.play_circle_outline,
                        color: kBlueBright,
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        f.extension?.toUpperCase() ?? '',
                        style: const TextStyle(color: kTextDim, fontSize: 9),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.image_outlined,
                        color: kBlueBright,
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        f.name.length > 10
                            ? '${f.name.substring(0, 8)}…'
                            : f.name,
                        style: const TextStyle(color: kTextDim, fontSize: 9),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          );
        }).toList(),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          const Icon(Icons.check_circle, color: kGreen, size: 14),
          const SizedBox(width: 6),
          Text(
            '${files.length} file dipilih',
            style: const TextStyle(
              color: kGreen,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onTap,
            child: const Text(
              'Ganti file',
              style: TextStyle(
                color: kBlueBright,
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

// ── Jenis Dropdown ────────────────────────────────────────────────────────
class _JenisDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  const _JenisDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    value: value,
    isDense: true,
    dropdownColor: kTextDim,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    iconEnabledColor: kTextDim,
    decoration: InputDecoration(
      hint: const Text(
        'Pilih jenis incident...',
        style: TextStyle(color: Colors.white, fontSize: 13),
      ),
      filled: true,
      fillColor: kNavy2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        borderSide: const BorderSide(color: kBlue, width: 1.5),
      ),
    ),
    items: const [
      DropdownMenuItem(value: 'kerusakan', child: Text('Kerusakan')),
      DropdownMenuItem(value: 'kecelakaan', child: Text('Kecelakaan')),
      DropdownMenuItem(value: 'kriminal', child: Text('Kriminalitas')),
      DropdownMenuItem(value: 'lainnya', child: Text('Lainnya')),
    ],
    onChanged: onChanged,
  );
}

// ── Map Picker Button ─────────────────────────────────────────────────────
class _MapPickerBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _MapPickerBtn({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: kBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.map_outlined, color: Colors.white, size: 22),
    ),
  );
}
