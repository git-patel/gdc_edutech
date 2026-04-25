import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'custom_text.dart';
import 'primary_button.dart';

/// Empty state: icon + title + subtitle + optional button.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.iconSize = 80,
    this.iconColor,
    this.padding,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final double iconSize;
  final Color? iconColor;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final effectiveIconColor = iconColor ?? colors.captionColor;
    final p = padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 32);

    final content = Padding(
      padding: p,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: effectiveIconColor),
          const SizedBox(height: 24),
          SectionTitle(title, textAlign: TextAlign.center),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 8),
            BodyText(subtitle!, textAlign: TextAlign.center),
          ],
          if (buttonText != null && onButtonPressed != null) ...[
            const SizedBox(height: 24),
            PrimaryButton(
              text: buttonText!,
              onPressed: onButtonPressed,
              size: ButtonSize.medium,
            ),
          ],
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: availableHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [content],
            ),
          ),
        );
      },
    );
  }
}
