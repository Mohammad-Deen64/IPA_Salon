import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF060816);
  static const navy = Color(0xFF080D1A);
  static const card = Color(0x14FFFFFF);
  static const purple = Color(0xFF6C63FF);
  static const violet = Color(0xFF8B5CF6);
  static const deepPurple = Color(0xFF9668FE);
  static const gold = Color(0xFFD4AF37);
  static const muted = Color(0xFF9CA3AF);
  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFEF4444);
  static const border = Color(0x22FFFFFF);

  static const gradient = LinearGradient(colors: [purple, violet]);
}

class AppPalette {
  const AppPalette({
    required this.background,
    required this.foreground,
    required this.muted,
    required this.card,
    required this.border,
    required this.input,
    required this.navBar,
  });

  final Color background;
  final Color foreground;
  final Color muted;
  final Color card;
  final Color border;
  final Color input;
  final Color navBar;

  static const dark = AppPalette(
    background: Color(0xFF060816),
    foreground: Color(0xFFFAFAFA),
    muted: Color(0xFF9CA3AF),
    card: Color(0x14FFFFFF),
    border: Color(0x22FFFFFF),
    input: Color(0xFF1A2035),
    navBar: Color(0xE60B1020),
  );

  static const light = AppPalette(
    background: Color(0xFFF9FAFB),
    foreground: Color(0xFF111827),
    muted: Color(0xFF6B7280),
    card: Color(0xFFFFFFFF),
    border: Color(0x1A000000),
    input: Color(0xFFF3F4F6),
    navBar: Color(0xF2FFFFFF),
  );

  static AppPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}
