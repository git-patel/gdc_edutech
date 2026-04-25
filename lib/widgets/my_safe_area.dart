import 'package:flutter/material.dart';

/// Safe area wrapper with optional top/bottom, background, and custom padding.
class MySafeArea extends StatelessWidget {
  const MySafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
    this.backgroundColor,
    this.padding,
    this.minimum,
    this.maintainBottomViewPadding = false,
  });

  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final EdgeInsets? minimum;
  final bool maintainBottomViewPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackground = backgroundColor ?? theme.scaffoldBackgroundColor;

    return Container(
      color: effectiveBackground,
      child: SafeArea(
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        minimum: minimum ?? EdgeInsets.zero,
        maintainBottomViewPadding: maintainBottomViewPadding,
        child: padding != null
            ? Padding(
                padding: padding!,
                child: child,
              )
            : child,
      ),
    );
  }
}
