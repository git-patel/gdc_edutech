import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// Main screen titles – 32sp, Poppins w600.
class AppTitle extends StatelessWidget {
  const AppTitle(
    this.data, {
    super.key,
    this.color,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.isMarquee = false,
  });

  final String data;
  final Color? color;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  /// When true, text scrolls horizontally (marquee) if it overflows.
  final bool isMarquee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final baseStyle = AppTextStyles.appTitle(colors);
    final textStyle = (style ?? baseStyle).copyWith(color: color ?? style?.color ?? baseStyle.color);
    if (isMarquee) return _TextMarquee(data: data, style: textStyle);
    return Text(
      data,
      style: textStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Section headers – 24sp, Poppins w600.
class SectionTitle extends StatelessWidget {
  const SectionTitle(
    this.data, {
    super.key,
    this.color,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.isMarquee = false,
  });

  final String data;
  final Color? color;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  /// When true, text scrolls horizontally (marquee) if it overflows.
  final bool isMarquee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final baseStyle = AppTextStyles.sectionTitle(colors);
    final textStyle = (style ?? baseStyle).copyWith(color: color ?? style?.color ?? baseStyle.color);
    if (isMarquee) return _TextMarquee(data: data, style: textStyle);
    return Text(
      data,
      style: textStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Card titles – 18sp, Poppins w600.
class CardTitle extends StatelessWidget {
  const CardTitle(
    this.data, {
    super.key,
    this.color,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.isMarquee = false,
  });

  final String data;
  final Color? color;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  /// When true, text scrolls horizontally (marquee) if it overflows.
  final bool isMarquee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final baseStyle = AppTextStyles.cardTitle(colors);
    final textStyle = (style ?? baseStyle).copyWith(color: color ?? style?.color ?? baseStyle.color);
    if (isMarquee) return _TextMarquee(data: data, style: textStyle);
    return Text(
      data,
      style: textStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Subtitles – 16sp, Inter w500.
class Subtitle extends StatelessWidget {
  const Subtitle(
    this.data, {
    super.key,
    this.color,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.isMarquee = false,
  });

  final String data;
  final Color? color;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  /// When true, text scrolls horizontally (marquee) if it overflows.
  final bool isMarquee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final baseStyle = AppTextStyles.subtitle(colors);
    final textStyle = (style ?? baseStyle).copyWith(color: color ?? style?.color ?? baseStyle.color);
    if (isMarquee) return _TextMarquee(data: data, style: textStyle);
    return Text(
      data,
      style: textStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Body text – 16sp, Inter w400.
class BodyText extends StatelessWidget {
  const BodyText(
    this.data, {
    super.key,
    this.color,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.isMarquee = false,
  });

  final String data;
  final Color? color;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  /// When true, text scrolls horizontally (marquee) if it overflows.
  final bool isMarquee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final baseStyle = AppTextStyles.bodyText(colors);
    final textStyle = (style ?? baseStyle).copyWith(color: color ?? style?.color ?? baseStyle.color);
    if (isMarquee) return _TextMarquee(data: data, style: textStyle);
    return Text(
      data,
      style: textStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Small body – 14sp, Inter w400.
class BodySmall extends StatelessWidget {
  const BodySmall(
    this.data, {
    super.key,
    this.color,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.isMarquee = false,
  });

  final String data;
  final Color? color;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  /// When true, text scrolls horizontally (marquee) if it overflows.
  final bool isMarquee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final baseStyle = AppTextStyles.bodySmall(colors);
    final textStyle = (style ?? baseStyle).copyWith(color: color ?? style?.color ?? baseStyle.color);
    if (isMarquee) return _TextMarquee(data: data, style: textStyle);
    return Text(
      data,
      style: textStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Captions – 12sp, Inter w400.
class Caption extends StatelessWidget {
  const Caption(
    this.data, {
    super.key,
    this.color,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.isMarquee = false,
  });

  final String data;
  final Color? color;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  /// When true, text scrolls horizontally (marquee) if it overflows.
  final bool isMarquee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final baseStyle = AppTextStyles.caption(colors);
    final textStyle = (style ?? baseStyle).copyWith(color: color ?? style?.color ?? baseStyle.color);
    if (isMarquee) return _TextMarquee(data: data, style: textStyle);
    return Text(
      data,
      style: textStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Internal widget: single-line horizontal marquee when text overflows.
class _TextMarquee extends StatefulWidget {
  const _TextMarquee({required this.data, required this.style});

  final String data;
  final TextStyle style;

  @override
  State<_TextMarquee> createState() => _TextMarqueeState();
}

class _TextMarqueeState extends State<_TextMarquee>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 8000);
  static const _gap = 32.0;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final textSpan = TextSpan(text: widget.data, style: widget.style);
        final painter = TextPainter(
          text: textSpan,
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout();
        final textWidth = painter.width;
        final totalWidth = textWidth + _gap;
        if (totalWidth <= width || width <= 0) {
          return Text(
            widget.data,
            style: widget.style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }
        return ClipRect(
          child: SizedBox(
            width: width,
            height: painter.height,
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: width,
              maxWidth: totalWidth * 2,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(-_animation.value * totalWidth, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.data, style: widget.style),
                        const SizedBox(width: _gap),
                        Text(widget.data, style: widget.style),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
