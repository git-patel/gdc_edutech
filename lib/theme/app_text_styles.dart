import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Named text styles for LearnFlow. Use via [textTheme] or style getters with [ColorScheme].
abstract final class AppTextStyles {
  AppTextStyles._();

  static TextStyle _poppins({double? fontSize, FontWeight? fontWeight}) =>
      GoogleFonts.poppins(fontSize: fontSize, fontWeight: fontWeight);

  static TextStyle _inter({double? fontSize, FontWeight? fontWeight}) =>
      GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight);

  /// Main screen titles – 32sp, Poppins w600, titleColor.
  static TextStyle appTitle(ColorScheme colors) =>
      _poppins(fontSize: 32, fontWeight: FontWeight.w600).copyWith(color: colors.titleColor);

  /// Section headers – 24sp, Poppins w600, titleColor.
  static TextStyle sectionTitle(ColorScheme colors) =>
      _poppins(fontSize: 24, fontWeight: FontWeight.w600).copyWith(color: colors.titleColor);

  /// Card titles – 18sp, Poppins w600, titleColor.
  static TextStyle cardTitle(ColorScheme colors) =>
      _poppins(fontSize: 18, fontWeight: FontWeight.w600).copyWith(color: colors.titleColor);

  /// Subtitles – 16sp, Inter w500, subtitleColor.
  static TextStyle subtitle(ColorScheme colors) =>
      _inter(fontSize: 16, fontWeight: FontWeight.w500).copyWith(color: colors.subtitleColor);

  /// Body text – 16sp, Inter w400, bodyTextColor.
  static TextStyle bodyText(ColorScheme colors) =>
      _inter(fontSize: 16, fontWeight: FontWeight.w400).copyWith(color: colors.bodyTextColor);

  /// Small body – 14sp, Inter w400, bodyTextColor.
  static TextStyle bodySmall(ColorScheme colors) =>
      _inter(fontSize: 14, fontWeight: FontWeight.w400).copyWith(color: colors.bodyTextColor);

  /// Captions – 12sp, Inter w400, captionColor.
  static TextStyle caption(ColorScheme colors) =>
      _inter(fontSize: 12, fontWeight: FontWeight.w400).copyWith(color: colors.captionColor);

  /// Full [TextTheme] using semantic colors from [colors].
  static TextTheme textTheme(ColorScheme colors) {
    return TextTheme(
      displayLarge: appTitle(colors),
      headlineMedium: sectionTitle(colors),
      titleLarge: cardTitle(colors),
      titleMedium: subtitle(colors),
      bodyLarge: bodyText(colors),
      bodyMedium: bodySmall(colors),
      bodySmall: caption(colors),
    );
  }
}
