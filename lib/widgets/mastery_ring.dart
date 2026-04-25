import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Circular progress ring for mastery % (chapter cards, profile).
class MasteryRing extends StatelessWidget {
  const MasteryRing({
    super.key,
    required this.progress,
    this.size = 56,
    this.strokeWidth,
    this.backgroundColor,
    this.progressColor,
    this.showLabel = true,
    this.labelStyle,
  }) : assert(progress >= 0 && progress <= 1, 'progress must be 0..1');

  final double progress;
  final double size;
  final double? strokeWidth;
  final Color? backgroundColor;
  final Color? progressColor;
  final bool showLabel;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final stroke = strokeWidth ?? (size * 0.12).clamp(4.0, 8.0);
    final bg = backgroundColor ?? colors.dividerColor;
    final fg = progressColor ?? colors.primary;

    final percent = (progress * 100).round();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: stroke,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(bg),
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: stroke,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
              strokeCap: StrokeCap.round,
            ),
          ),
          if (showLabel)
            Text(
              '$percent%',
              style: labelStyle ??
                  theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.titleColor,
                    fontSize: size * 0.2,
                  ),
            ),
        ],
      ),
    );
  }
}
