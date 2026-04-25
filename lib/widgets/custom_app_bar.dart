import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'custom_text.dart';

/// Custom app bar with title, actions, back button, elevation. Theme-based.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.centerTitle = true,
    this.showBackButton = false,
    this.onBackPressed,
    this.elevation,
    this.backgroundColor,
    this.foregroundColor,
    this.leading,
    this.bottom,
    this.automaticallyImplyLeading = true,
  });

  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final double? elevation;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final canPop = Navigator.of(context).canPop();
    final showLeading = showBackButton && (onBackPressed != null || canPop);

    return AppBar(
      backgroundColor: backgroundColor ?? colors.surface,
      foregroundColor: foregroundColor ?? colors.onSurface,
      elevation: elevation ?? 0,
      scrolledUnderElevation: elevation ?? 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading && !showBackButton && leading == null,
      leading: leading ??
          (showLeading
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                )
              : null),
      title: titleWidget ??
          (title != null
              ? Subtitle(
                  title!,
                  style: theme.textTheme.titleLarge?.copyWith(color: colors.titleColor),
                )
              : null),
      actions: actions,
      bottom: bottom,
    );
  }
}
