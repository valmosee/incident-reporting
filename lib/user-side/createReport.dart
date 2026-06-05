import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../showMap.dart';
import '../global.dart' as global;
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';

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

  // ── Logic: tidak diubah ──────────────────────────────────────────────────

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

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      appBar: AppBar(
        backgroundColor: kNavy,
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Upload Foto / Video ──────────────────────────────────────
            const FieldLabel('Foto / Video'),
            const SizedBox(height: 8),
            _MediaPicker(files: _resultFile?.files ?? [], onTap: _pilihFile),
            const SizedBox(height: 20),

            // ── Judul ───────────────────────────────────────────────────
            const FieldLabel('Judul Laporan'),
            const SizedBox(height: 8),
            AppTextField(
              controller: _titleCtrl,
              hint: 'Contoh: Jalan rusak di...',
            ),
            const SizedBox(height: 16),

            // ── Jenis Incident ──────────────────────────────────────────
            const FieldLabel('Jenis Incident'),
            const SizedBox(height: 8),
            _JenisDropdown(
              value: _selectedJenis,
              onChanged: (v) => setState(() => _selectedJenis = v),
            ),
            const SizedBox(height: 16),

            // ── Deskripsi ───────────────────────────────────────────────
            const FieldLabel('Deskripsi Kerusakan'),
            const SizedBox(height: 8),
            AppTextField(
              controller: _descCtrl,
              hint: 'Jelaskan kondisi kejadian...',
              maxLines: 4,
            ),
            const SizedBox(height: 20),

            // ── Lokasi ──────────────────────────────────────────────────
            const FieldLabel('Lokasi'),
            const SizedBox(height: 8),
            _LocationRow(controller: _addressCtrl, onPickMap: _pilihlokasi),
            const SizedBox(height: 20),

            // ── Kirim ───────────────────────────────────────────────────
            PrimaryButton(
              label: 'Kirim Laporan',
              loading: _submitting,
              onPressed: _submit,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MediaPicker — area upload foto/video
// ─────────────────────────────────────────────────────────────────────────────

class _MediaPicker extends StatelessWidget {
  final List<PlatformFile> files;
  final VoidCallback onTap;

  const _MediaPicker({required this.files, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kNavy2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: files.isEmpty ? _emptyState() : _fileGrid(),
    ),
  );

  Widget _emptyState() => const Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.perm_media_outlined, size: 40, color: Colors.white38),
      SizedBox(height: 8),
      Text(
        'Ketuk untuk pilih foto / video',
        style: TextStyle(color: Colors.white38),
      ),
      SizedBox(height: 4),
      Text(
        'Bisa pilih lebih dari 1 file',
        style: TextStyle(color: Colors.white24, fontSize: 11),
      ),
    ],
  );

  Widget _fileGrid() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: files.map((f) => _FileTile(file: f)).toList(),
      ),
      const SizedBox(height: 10),
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
  );
}

class _FileTile extends StatelessWidget {
  final PlatformFile file;
  const _FileTile({required this.file});

  bool get _isVideo =>
      ['mp4', 'mov', 'avi'].contains(file.extension?.toLowerCase());

  @override
  Widget build(BuildContext context) => Container(
    width: 80,
    height: 80,
    decoration: BoxDecoration(
      color: kNavy,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _isVideo ? Icons.videocam_outlined : Icons.image_outlined,
          color: Colors.white54,
          size: 28,
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            file.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _JenisDropdown — dropdown pilih jenis incident
// ─────────────────────────────────────────────────────────────────────────────

class _JenisDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _JenisDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    value: value,
    dropdownColor: kNavy2,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    iconEnabledColor: Colors.white38,
    decoration: InputDecoration(
      hintText: 'Pilih jenis incident...',
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
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

// ─────────────────────────────────────────────────────────────────────────────
// _LocationRow — field alamat + tombol buka peta
// ─────────────────────────────────────────────────────────────────────────────

class _LocationRow extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onPickMap;

  const _LocationRow({required this.controller, required this.onPickMap});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: AppTextField(
          controller: controller,
          hint: 'Ketuk ikon peta untuk pilih lokasi...',
          readOnly: true,
        ),
      ),
      const SizedBox(width: 10),
      GestureDetector(
        onTap: onPickMap,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: kBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.map_outlined, color: Colors.white),
        ),
      ),
    ],
  );
}
