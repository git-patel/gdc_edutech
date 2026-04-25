import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Small badge showing study streak (flame icon + number).
class StreakBadge extends StatelessWidget {
  const StreakBadge({
    super.key,
    required this.streak,
    this.size = StreakBadgeSize.medium,
    this.backgroundColor,
    this.onTap,
  });

  final int streak;
  final StreakBadgeSize size;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bg = backgroundColor ?? colors.primaryContainer;
    final strokeColor = AppColors.streakColor;

    final (double iconSize, double fontSize) = switch (size) {
      StreakBadgeSize.small => (16.0, 12.0),
      StreakBadgeSize.medium => (20.0, 14.0),
      StreakBadgeSize.large => (24.0, 16.0),
    };

    final child = Container(
      padding: EdgeInsets.symmetric(
        horizontal: size == StreakBadgeSize.small ? 8 : 12,
        vertical: size == StreakBadgeSize.small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: strokeColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded, size: iconSize, color: strokeColor),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.titleColor,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: child);
    }
    return child;
  }
}

enum StreakBadgeSize { small, medium, large }
