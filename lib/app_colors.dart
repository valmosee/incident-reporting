import 'package:flutter/material.dart';

// ── Palet warna utama aplikasi ────────────────────────────────────────────
// Dipakai bersama oleh dashboardUser, historyReport, createReport, showMap.
// Import: import '../app_colors.dart';  (sesuaikan path relatif)

const kNavy        = Color(0xFF0D1B2A); // background utama
const kNavy2       = Color(0xFF1A2D42); // card / panel
const kNavy3       = Color(0xFF132236); // mini-map background
const kBlue        = Color(0xFF1565C0); // tombol primer, border aktif
const kBlueBright  = Color(0xFF4D9EFF); // aksen, link
const kGreen       = Color(0xFF22C55E); // status selesai / tombol tambah
const kAmber       = Color(0xFFF59E0B); // status menunggu
const kRed         = Color(0xFFEF4444); // error
const kBlueTag     = Color(0xFF3B82F6); // status diproses

const kTextMuted   = Color(0x99FFFFFF); // teks sekunder (~60 % putih)
const kTextDim     = Color(0x59FFFFFF); // teks tersier  (~35 % putih)
const kBorder      = Color(0x1AFFFFFF); // border card   (~10 % putih)

// ── Status helpers ────────────────────────────────────────────────────────

/// Mengembalikan (icon, warna icon, warna background icon) berdasarkan status.
(IconData, Color, Color) statusIconStyle(String status) {
  switch (status) {
    case 'proses':
      return (Icons.build_outlined,       const Color(0xFF60A5FA), const Color(0x263B82F6));
    case 'selesai':
      return (Icons.check_circle_outline, const Color(0xFF4ADE80), const Color(0x2622C55E));
    default:
      return (Icons.access_time_outlined, const Color(0xFFFCD34D), const Color(0x26F59E0B));
  }
}

/// Mengembalikan (label, textColor, bgColor, borderColor) berdasarkan status.
(String, Color, Color, Color) statusBadgeStyle(String status) {
  switch (status) {
    case 'proses':
      return ('Diproses', const Color(0xFF60A5FA), const Color(0x263B82F6), const Color(0x4D3B82F6));
    case 'selesai':
      return ('Selesai',  const Color(0xFF4ADE80), const Color(0x2622C55E), const Color(0x4D22C55E));
    default:
      return ('Menunggu', const Color(0xFFFCD34D), const Color(0x26F59E0B), const Color(0x4DF59E0B));
  }
}