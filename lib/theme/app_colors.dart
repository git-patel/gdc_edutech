import 'package:flutter/material.dart';

/// Fixed color definitions for LearnFlow. Use these via Theme, never hardcode.
abstract final class AppColors {
  AppColors._();

  // ─── Semantic (fixed hex, same in light & dark) ──────────────────────────
  static const Color successColor = Color(0xFF10B981);
  static const Color streakColor = Color(0xFFF59E0B);

  // ─── Light mode ColorScheme ─────────────────────────────────────────────
  static const ColorScheme light = ColorScheme.light(
    primary: Color(0xFF4F46E5),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE0E7FF),
    secondary: Color(0xFF14B8A6),
    onSecondary: Color(0xFFFFFFFF),
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    onBackground: Color(0xFF1E2937),
    onSurface: Color(0xFF1E2937),
    error: Color(0xFFEF4444),
    onError: Color(0xFFFFFFFF),
  );

  // ─── Dark mode ColorScheme ─────────────────────────────────────────────
  static const ColorScheme dark = ColorScheme.dark(
    primary: Color(0xFF6366F1),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF312E81),
    secondary: Color(0xFF2DD4BF),
    onSecondary: Color(0xFF0F172A),
    background: Color(0xFF0F172A),
    surface: Color(0xFF1E2937),
    onBackground: Color(0xFFF1F5F9),
    onSurface: Color(0xFFF1F5F9),
    error: Color(0xFFF87171),
    onError: Color(0xFF0F172A),
  );
}

/// Semantic colors derived from [ColorScheme]. Use these names in UI.
extension AppColorSchemeX on ColorScheme {
  /// Main headings (→ onBackground).
  Color get titleColor => onBackground;

  /// Section subtitles (→ onSurface 75%).
  Color get subtitleColor => onSurface.withValues(alpha: 0.75);

  /// Body copy (→ onSurface).
  Color get bodyTextColor => onSurface;

  /// Secondary captions (→ onSurface 60%).
  Color get captionColor => onSurface.withValues(alpha: 0.6);

  /// Dividers (→ onSurface 10%).
  Color get dividerColor => onSurface.withValues(alpha: 0.1);
}
