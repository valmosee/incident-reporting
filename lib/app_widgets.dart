import 'package:flutter/material.dart';
import 'app_colors.dart';

// ── Status Badge ──────────────────────────────────────────────────────────
/// Badge berwarna sesuai status laporan (pending / proses / selesai).
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

// ── Jenis Badge ───────────────────────────────────────────────────────────
/// Badge abu-abu kecil yang menampilkan jenis laporan.
class JenisBadge extends StatelessWidget {
  final String jenis;
  const JenisBadge({super.key, required this.jenis});

  String get _label => switch (jenis) {
    'kecelakaan' => 'Kecelakaan',
    'kriminal'   => 'Kriminalitas',
    'lainnya'    => 'Lainnya',
    _            => 'Kerusakan',
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.07),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(_label, style: const TextStyle(color: kTextMuted, fontSize: 10)),
  );
}

// ── Section Title ─────────────────────────────────────────────────────────
/// Judul section dengan optional link "Lihat semua →" di kanan.
class SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(color: kBlueBright, fontSize: 12),
            ),
          ),
      ],
    ),
  );
}

// ── App Panel ─────────────────────────────────────────────────────────────
/// Container card dengan background navy2, border tipis, dan radius 14.
class AppPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AppPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: kNavy2,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kBorder),
    ),
    child: child,
  );
}

// ── Icon Button Bulat ─────────────────────────────────────────────────────
/// Tombol ikon kotak kecil (36×36) dengan warna background bebas.
class AppIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color bgColor;
  final Color iconColor;

  const AppIconBtn({
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

// ── Form Text Field ───────────────────────────────────────────────────────
/// TextField bergaya navy2 yang dipakai di createReport & showMap.
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? initialValue;
  final int maxLines;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.initialValue,
    this.maxLines = 1,
    this.readOnly = false,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    initialValue: controller == null ? initialValue : null,
    maxLines: maxLines,
    readOnly: readOnly,
    onChanged: onChanged,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: kTextDim, fontSize: 13),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: kNavy2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBlue, width: 1.5),
      ),
    ),
  );
}

// ── Form Label ────────────────────────────────────────────────────────────
/// Label kecil di atas setiap field form.
class FormLabel extends StatelessWidget {
  final String text;
  const FormLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: kTextMuted,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    ),
  );
}

// ── Primary Button ────────────────────────────────────────────────────────
/// Tombol full-width bergaya biru dengan loading state.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
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
        elevation: 0,
      ),
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
    ),
  );
}