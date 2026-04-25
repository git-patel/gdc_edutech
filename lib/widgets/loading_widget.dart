import 'package:flutter/material.dart';

import 'custom_text.dart';

/// Centered loading indicator. Theme-aware.
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    super.key,
    this.message,
    this.size = 40,
    this.strokeWidth,
    this.color,
  });

  final String? message;
  final double size;
  final double? strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final stroke = strokeWidth ?? 3.0;
    final indicatorColor = color ?? colors.primary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: stroke,
              valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            ),
          ),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 16),
            BodySmall(message!, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
