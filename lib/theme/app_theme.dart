import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WARNA
// ─────────────────────────────────────────────────────────────────────────────

const kNavy = Color(0xFF0D1B2A); // background utama
const kNavy2 = Color(0xFF1A2D42); // card / panel
const kNavy3 = Color(0xFF132236); // surface lebih gelap (map preview)
const kBlue = Color(0xFF1565C0); // aksi primer (tombol, border focus)
const kBlueBright = Color(0xFF4D9EFF); // link / highlight
const kGreen = Color(0xFF22C55E); // status selesai / buat laporan
const kAmber = Color(0xFFF59E0B); // status menunggu
const kRed = Color(0xFFEF4444); // error
const kBlueTag = Color(0xFF3B82F6); // status diproses

const kTextMuted = Color(0x99FFFFFF); // teks sekunder
const kTextDim = Color(0x59FFFFFF); // teks tersier / placeholder
const kBorder = Color(0x1AFFFFFF); // border halus

// ─────────────────────────────────────────────────────────────────────────────
// BADGE & STATUS HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// Kembalikan (ikon, warna ikon, warna background ikon) berdasarkan status.
(IconData, Color, Color) statusIconStyle(String status) {
  switch (status) {
    case 'proses':
      return (
        Icons.build_outlined,
        const Color(0xFF60A5FA),
        const Color(0x263B82F6),
      );
    case 'selesai':
      return (
        Icons.check_circle_outline,
        const Color(0xFF4ADE80),
        const Color(0x2622C55E),
      );
    default:
      return (
        Icons.access_time_outlined,
        const Color(0xFFFCD34D),
        const Color(0x26F59E0B),
      );
  }
}

/// Kembalikan (label, warna teks, warna bg, warna border) berdasarkan status.
(String, Color, Color, Color) statusBadgeStyle(String status) {
  switch (status) {
    case 'proses':
      return (
        'Diproses',
        const Color(0xFF60A5FA),
        const Color(0x263B82F6),
        const Color(0x4D3B82F6),
      );
    case 'selesai':
      return (
        'Selesai',
        const Color(0xFF4ADE80),
        const Color(0x2622C55E),
        const Color(0x4D22C55E),
      );
    default:
      return (
        'Menunggu',
        const Color(0xFFFCD34D),
        const Color(0x26F59E0B),
        const Color(0x4DF59E0B),
      );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DECORATIONS
// ─────────────────────────────────────────────────────────────────────────────

/// Dekorasi card/panel standar.
BoxDecoration get kCardDecoration => BoxDecoration(
  color: kNavy2,
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: kBorder),
);

/// Dekorasi input field standar.
InputDecoration kInputDecoration({
  String? hint,
  Widget? prefix,
  Widget? suffix,
}) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: kTextDim, fontSize: 14),
  prefixIcon: prefix,
  suffixIcon: suffix,
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
);

// ─────────────────────────────────────────────────────────────────────────────
// TEXT STYLES
// ─────────────────────────────────────────────────────────────────────────────

const kStyleSectionTitle = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.w700,
  fontSize: 15,
);

const kStyleCardTitle = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.w600,
  fontSize: 13,
);

const kStyleLabel = TextStyle(
  color: kTextMuted,
  fontWeight: FontWeight.w500,
  fontSize: 13,
);

const kStyleMuted = TextStyle(color: kTextMuted, fontSize: 12);
const kStyleDim = TextStyle(color: kTextDim, fontSize: 11);
