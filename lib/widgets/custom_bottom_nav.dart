import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Bottom navigation bar: Home, My Class, Library, Me. Icons, labels, badges.
class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.badges,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  /// Optional badge counts (e.g. notifications). Index → count; null or 0 = no badge.
  final Map<int, int>? badges;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;

  static const int _home = 0;
  static const int _myClass = 1;
  static const int _tutor = 2;
  static const int _library = 3;
  static const int _me = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bg = backgroundColor ?? colors.surface;
    final selected = selectedColor ?? colors.primary;
    final unselected = unselectedColor ?? colors.captionColor;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: currentIndex == _home,
                selectedColor: selected,
                unselectedColor: unselected,
                badgeCount: badges?[_home],
                onTap: () => onTap(_home),
              ),
              _NavItem(
                icon: Icons.menu_book_rounded,
                label: 'My Class',
                isSelected: currentIndex == _myClass,
                selectedColor: selected,
                unselectedColor: unselected,
                badgeCount: badges?[_myClass],
                onTap: () => onTap(_myClass),
              ),
              _NavItem(
                icon: Icons.auto_awesome,
                label: 'Tutor',
                isSelected: currentIndex == _tutor,
                selectedColor: selected,
                unselectedColor: unselected,
                badgeCount: badges?[_tutor],
                onTap: () => onTap(_tutor),
              ),
              _NavItem(
                icon: Icons.library_books_rounded,
                label: 'Library',
                isSelected: currentIndex == _library,
                selectedColor: selected,
                unselectedColor: unselected,
                badgeCount: badges?[_library],
                onTap: () => onTap(_library),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Me',
                isSelected: currentIndex == _me,
                selectedColor: selected,
                unselectedColor: unselected,
                badgeCount: badges?[_me],
                onTap: () => onTap(_me),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    this.badgeCount,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final int? badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected ? selectedColor : unselectedColor;
    final hasBadge = badgeCount != null && badgeCount! > 0;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, size: 26, color: color),
                    if (hasBadge)
                      Positioned(
                        top: -4,
                        right: -8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Center(
                            child: Text(
                              badgeCount! > 99 ? '99+' : '$badgeCount',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onError,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
