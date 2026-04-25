import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'primary_button.dart';

/// Secondary filled button (secondary color). Same API as [PrimaryButton].
class SecondaryButton extends StatefulWidget {
  const SecondaryButton({
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
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final effectiveOnPressed = widget.enabled && !widget.isLoading ? widget.onPressed : null;

    final Widget buttonChild = Material(
      color: colors.secondary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: effectiveOnPressed,
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
                        valueColor: AlwaysStoppedAnimation<Color>(colors.onSecondary),
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
                            color: colors.onSecondary,
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

    return widget.width != null ? SizedBox(width: widget.width, child: buttonChild) : buttonChild;
  }
}

/// Outline-only button (tertiary action). Same API as [PrimaryButton].
class OutlineButton extends StatefulWidget {
  const OutlineButton({
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
  State<OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<OutlineButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final effectiveOnPressed = widget.enabled && !widget.isLoading ? widget.onPressed : null;
    final borderColor = effectiveOnPressed != null ? colors.primary : colors.dividerColor;
    final textColor = effectiveOnPressed != null ? colors.primary : colors.captionColor;

    final Widget buttonChild = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: effectiveOnPressed,
        borderRadius: BorderRadius.circular(16),
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? kButtonTapScale : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            padding: widget.padding ?? paddingForButtonSize(widget.size),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.5),
            ),
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
                        valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
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
                            color: textColor,
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

    return widget.width != null ? SizedBox(width: widget.width, child: buttonChild) : buttonChild;
  }
}
