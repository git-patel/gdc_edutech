import 'package:flutter/material.dart';

/// Tap scale for press animation. Shared by primary/secondary/outline buttons.
const double kButtonTapScale = 0.96;

/// Button size padding. Shared by primary/secondary/outline buttons.
EdgeInsets paddingForButtonSize(ButtonSize size) {
  switch (size) {
    case ButtonSize.small:
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
    case ButtonSize.medium:
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
    case ButtonSize.large:
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 18);
  }
}

/// Min height for button size.
double minHeightForButtonSize(ButtonSize size) {
  switch (size) {
    case ButtonSize.small:
      return 40;
    case ButtonSize.medium:
      return 48;
    case ButtonSize.large:
      return 56;
  }
}

enum ButtonSize { small, medium, large }

/// Primary filled button (main CTA). Uses theme primary color.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.size = ButtonSize.medium,
    this.icon,
    this.iconAfter,
    this.width,
    this.padding,
    this.style,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final ButtonSize size;
  final Widget? icon;
  final Widget? iconAfter;
  final double? width;
  final EdgeInsets? padding;
  final ButtonStyle? style;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final effectiveOnPressed = widget.enabled && !widget.isLoading ? widget.onPressed : null;

    final child = Material(
      color: colors.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: effectiveOnPressed == null
            ? null
            : () {
                effectiveOnPressed();
              },
        borderRadius: BorderRadius.circular(16),
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? kButtonTapScale : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            padding: widget.padding ?? paddingForButtonSize(widget.size),
            constraints: BoxConstraints(
              minHeight: minHeightForButtonSize(widget.size),
              minWidth: widget.width ?? 0,
            ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.onPrimary),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[widget.icon!, const SizedBox(width: 10)],
                      Text(
                        widget.text,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.iconAfter != null) ...[const SizedBox(width: 10), widget.iconAfter!],
                    ],
                  ),
            ),
          ),
        ),
      ),
    );

    return widget.width != null
        ? SizedBox(width: widget.width, child: child)
        : child;
  }
}
