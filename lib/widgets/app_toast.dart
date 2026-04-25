import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'custom_text.dart';

/// Where the toast appears on screen.
enum ToastPosition {
  top,
  bottom,
  center,
}

/// Style / type of message (colors + optional icon).
enum ToastType {
  error,
  success,
  info,
  plain,
}

/// Customizable toast/message overlay. Use [AppToast.show] to display.
class AppToast {
  AppToast._();

  static OverlayEntry? _currentEntry;

  /// Show a toast. Only one at a time; new call replaces or dismisses the previous.
  static void show(
    BuildContext context, {
    required String message,
    ToastPosition position = ToastPosition.bottom,
    ToastType type = ToastType.plain,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
    EdgeInsets? margin,
    double? maxWidth,
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final (Color bg, Color onBg, IconData? icon) = switch (type) {
      ToastType.error => (colors.error, colors.onError, Icons.error_outline_rounded),
      ToastType.success => (AppColors.successColor, Colors.white, Icons.check_circle_outline_rounded),
      ToastType.info => (colors.primary, colors.onPrimary, Icons.info_outline_rounded),
      ToastType.plain => (colors.surface, colors.onSurface, null),
    };

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastOverlay(
        message: message,
        position: position,
        backgroundColor: bg,
        foregroundColor: onBg,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
        margin: margin ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        maxWidth: maxWidth ?? 400,
        onDismiss: () {
          entry.remove();
          _currentEntry = null;
        },
        duration: duration,
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  /// Show at bottom (snackbar-style).
  static void showBottom(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.plain,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      position: ToastPosition.bottom,
      type: type,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Show at top (toast-style).
  static void showTop(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.plain,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      position: ToastPosition.top,
      type: type,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Dismiss the current toast if any.
  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _ToastOverlay extends StatefulWidget {
  const _ToastOverlay({
    required this.message,
    required this.position,
    required this.backgroundColor,
    required this.foregroundColor,
    this.icon,
    this.actionLabel,
    this.onAction,
    required this.margin,
    required this.maxWidth,
    required this.onDismiss,
    required this.duration,
  });

  final String message;
  final ToastPosition position;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsets margin;
  final double maxWidth;
  final VoidCallback onDismiss;
  final Duration duration;

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    final dy = widget.position == ToastPosition.top ? -1.0 : (widget.position == ToastPosition.bottom ? 1.0 : 0.0);
    _slide = Tween<Offset>(begin: Offset(0, dy), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    Future.delayed(widget.duration, () {
      if (mounted) _controller.reverse().then((_) => widget.onDismiss());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: Colors.transparent,
      child: SafeArea(
        top: widget.position == ToastPosition.bottom,
        bottom: widget.position == ToastPosition.top,
        left: false,
        right: false,
        child: Align(
          alignment: switch (widget.position) {
            ToastPosition.top => Alignment.topCenter,
            ToastPosition.bottom => Alignment.bottomCenter,
            ToastPosition.center => Alignment.center,
          },
          child: Padding(
            padding: widget.margin,
            child: FadeTransition(
              opacity: _opacity,
              child: SlideTransition(
                position: _slide,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: widget.maxWidth),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: widget.backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 22, color: widget.foregroundColor),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              color: widget.foregroundColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (widget.actionLabel != null && widget.onAction != null) ...[
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () {
                              widget.onAction?.call();
                              widget.onDismiss();
                            },
                            child: Text(
                              widget.actionLabel!,
                              style: TextStyle(color: widget.foregroundColor, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return child;
  }
}
