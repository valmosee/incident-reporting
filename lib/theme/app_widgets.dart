import 'package:flutter/material.dart';
import 'app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppCard — panel / card standar
// ─────────────────────────────────────────────────────────────────────────────

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) =>
      Container(padding: padding, decoration: kCardDecoration, child: child);
}

// ─────────────────────────────────────────────────────────────────────────────
// StatusBadge — chip warna berdasarkan status laporan
// ─────────────────────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, textColor, bgColor, borderColor) = statusBadgeStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// JenisBadge — chip abu-abu kecil untuk jenis laporan
// ─────────────────────────────────────────────────────────────────────────────

class JenisBadge extends StatelessWidget {
  final String jenis;
  const JenisBadge({super.key, required this.jenis});

  String get _label => switch (jenis) {
    'kecelakaan' => 'Kecelakaan',
    'kriminal' => 'Kriminalitas',
    'lainnya' => 'Lainnya',
    _ => 'Kerusakan',
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.07),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(_label, style: kStyleDim),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AppIconButton — tombol ikon bulat kecil di header
// ─────────────────────────────────────────────────────────────────────────────

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color bgColor;
  final Color iconColor;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.bgColor = kNavy2,
    this.iconColor = kTextMuted,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: iconColor, size: 18),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SectionHeader — judul baris dengan optional "Lihat semua →"
// ─────────────────────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: kStyleSectionTitle),
      if (actionLabel != null)
        GestureDetector(
          onTap: onAction,
          child: Text(
            actionLabel!,
            style: const TextStyle(color: kBlueBright, fontSize: 12),
          ),
        ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTextField — TextField dengan styling gelap standar
// ─────────────────────────────────────────────────────────────────────────────

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final String? initialValue;
  final int maxLines;
  final bool readOnly;

  const AppTextField({
    super.key,
    this.controller,
    this.hint,
    this.initialValue,
    this.maxLines = 1,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    initialValue: controller == null ? initialValue : null,
    maxLines: maxLines,
    readOnly: readOnly,
    style: const TextStyle(color: Colors.white),
    decoration: kInputDecoration(hint: hint),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// FieldLabel — label kecil di atas form field
// ─────────────────────────────────────────────────────────────────────────────

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(text, style: kStyleLabel);
}

// ─────────────────────────────────────────────────────────────────────────────
// LoadingCenter — spinner tengah layar
// ─────────────────────────────────────────────────────────────────────────────

class LoadingCenter extends StatelessWidget {
  const LoadingCenter({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: kBlueBright));
}

// ─────────────────────────────────────────────────────────────────────────────
// ErrorCenter — tampilan error + tombol retry
// ─────────────────────────────────────────────────────────────────────────────

class ErrorCenter extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorCenter({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: kRed, size: 48),
          const SizedBox(height: 12),
          Text(message, style: kStyleMuted, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: kBlue),
            child: const Text(
              'Coba lagi',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PrimaryButton — tombol aksi besar lebar penuh
// ─────────────────────────────────────────────────────────────────────────────

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: kBlue,
        disabledBackgroundColor: kBlue.withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
    ),
  );
}
