import 'package:flutter/material.dart';

abstract final class AppPalette {
  static const Color background = Color(0xFF000000);
  static const Color secondaryA = Color(0xFF0A0A0A);
  static const Color secondaryB = Color(0xFF111111);
  static const Color card = Color(0xFF121212);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF6B6B6B);

  static const Color neutral = Color(0xFF424242); // Mid-grey
  static const Color surface = Color(0xFF1E1E1E); // Standard Surface
  static const Color surfaceLight = Color(0xFF2C2C2C); // Slightly Lighter

  static const Color border = Color.fromRGBO(255, 255, 255, 0.12);

  static const Color pureWhite = Color(0xFFFFFFFF);
}
