import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import 'custom_text.dart';

/// Shows [title] as CardTitle. If it would exceed 2 lines at the given width,
/// shows a single-line marquee instead.
class TitleMarquee extends StatelessWidget {
  const TitleMarquee({
    super.key,
    required this.title,
    this.style,
    this.color,
  });

  final String title;
  final TextStyle? style;
  final Color? color;

  /// Returns true if [text] would need more than 2 lines with [style] in [maxWidth].
  static bool _needsMarquee(String text, TextStyle style, double maxWidth) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 2,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final style = this.style ?? AppTextStyles.cardTitle(colors);
    final textStyle = style.copyWith(color: color ?? style.color);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        if (maxWidth <= 0) {
          return CardTitle(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: this.style,
            color: color,
          );
        }
        final useMarquee = _needsMarquee(title, textStyle, maxWidth);
        if (!useMarquee) {
          return CardTitle(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: this.style,
            color: color,
          );
        }
        return _AnimatedMarquee(title: title, textStyle: textStyle);
      },
    );
  }
}

class _AnimatedMarquee extends StatefulWidget {
  const _AnimatedMarquee({required this.title, required this.textStyle});

  final String title;
  final TextStyle textStyle;

  @override
  State<_AnimatedMarquee> createState() => _AnimatedMarqueeState();
}

class _AnimatedMarqueeState extends State<_AnimatedMarquee>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MarqueeLine(
      title: widget.title,
      textStyle: widget.textStyle,
      animation: _animation,
    );
  }
}

class _MarqueeLine extends StatelessWidget {
  const _MarqueeLine({
    required this.title,
    required this.textStyle,
    required this.animation,
  });

  final String title;
  final TextStyle textStyle;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final textSpan = TextSpan(text: title, style: textStyle);
        final painter = TextPainter(
          text: textSpan,
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout();
        final textWidth = painter.width;
        final gap = 32.0;
        final totalWidth = textWidth + gap;
        if (totalWidth <= width) {
          return Text(title, style: textStyle, maxLines: 1, overflow: TextOverflow.ellipsis);
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
                animation: animation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(-animation.value * totalWidth, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: textStyle),
                        SizedBox(width: gap),
                        Text(title, style: textStyle),
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
