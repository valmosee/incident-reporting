import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    surface:          const Color(0xFFF4F6FB),
    primary:          const Color(0xFF1A5CFF),
    secondary:        const Color(0xFF0A2540),
    onPrimary:        Colors.white,
    onSurface:        const Color(0xFF0A2540),
    surfaceContainer: Colors.white,
    outline:          const Color(0xFFD0D8EE),
    error:            const Color(0xFFE53935),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1A5CFF),
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    surface:          const Color.fromARGB(175, 0, 0, 0),
    primary:          const Color(0xFF1A5CFF),
    secondary:        const Color(0xFF0A2540),
    onPrimary:        Colors.white,
    onSurface:        const Color(0xFFE8EDF8),
    surfaceContainer: const Color(0xFF112236),
    outline:          const Color(0xFF1E3A5F),
    error:            const Color(0xFFE53935),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1A5CFF),
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
);