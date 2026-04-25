import 'package:flutter/material.dart';

/// Design reference size (logical pixels). Used to scale layout for different screens.
const double _kDesignWidth = 392.0;
const double _kDesignHeight = 783.0;

/// Maximum scale factor so layouts don't grow too large on big tablets.
const double _kMaxScale = 1.35;

/// Responsive layout helpers. Use these instead of hardcoded sizes so the app
/// adapts to small phones, large phones, and tablets.
extension Responsive on BuildContext {
  /// Screen size (same as MediaQuery.sizeOf(this)).
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  /// Scale factors relative to design size.
  double get _scaleW => (screenWidth / _kDesignWidth).clamp(0.5, _kMaxScale);
  double get _scaleH => (screenHeight / _kDesignHeight).clamp(0.5, _kMaxScale);
  /// Unified scale (use for spacing, radius, icons) so UI doesn't stretch too much on one axis.
  double get scale => _scaleW < _scaleH ? _scaleW : _scaleH;

  /// Height scaled by screen height. Use for vertical spacing and heights.
  /// [value] = size at design height 783.
  double rH(double value) => value * _scaleH;

  /// Width scaled by screen width. Use for horizontal spacing and widths.
  /// [value] = size at design width 392.
  double rW(double value) => value * _scaleW;

  /// Spacing/size that scales with the smaller of width/height (keeps proportions).
  /// Use for padding, gaps, border radius, icon size.
  double rSp(double value) => value * scale;

  /// Font size scaled (optional). Use if you want text to scale; otherwise keep fixed in theme.
  double rFont(double value) => value * scale;

  /// Returns a [childAspectRatio] for a grid so that each cell has at least
  /// [minHeightFraction] of screen height (e.g. 0.22 = 22%).
  /// [crossAxisCount] and [horizontalPadding], [mainAxisSpacing], [crossAxisSpacing]
  /// should match your GridView to compute cell width correctly.
  double gridChildAspectRatio({
    required int crossAxisCount,
    double minHeightFraction = 0.22,
    double horizontalPadding = 32,
    double mainAxisSpacing = 12,
    double crossAxisSpacing = 12,
  }) {
    final availableWidth = screenWidth - horizontalPadding - (crossAxisSpacing * (crossAxisCount - 1));
    final cellWidth = availableWidth / crossAxisCount;
    final cellHeight = screenHeight * minHeightFraction;
    if (cellHeight <= 0) return 1.0;
    return cellWidth / cellHeight;
  }
}
