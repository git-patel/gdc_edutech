import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import 'custom_text.dart';
import 'title_marquee.dart';

const double _kTapScale = 0.96;

/// Reusable card for subjects, chapters, continue learning, library items.
class ContentCard extends StatefulWidget {
  const ContentCard({
    super.key,
    required this.title,
    this.subtitle,
    this.thumbnail,
    this.thumbnailHeight = 120,
    this.progress,
    this.isPremium = false,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.child,
  });

  final String title;
  final String? subtitle;
  final Widget? thumbnail;
  /// Height of thumbnail area when [thumbnail] is set. Use a smaller value (e.g. 72) in constrained layouts.
  final double thumbnailHeight;
  final double? progress;
  final bool isPremium;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Widget? child;

  @override
  State<ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<ContentCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final surface = widget.backgroundColor ?? colors.surface;
    final r = context;

    final padding = widget.padding ?? EdgeInsets.all(r.rSp(16));
    final cardRadius = r.rSp(20);
    final gap = r.rSp(12);
    final smallGap = r.rSp(4);

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: colors.dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.thumbnail != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(r.rSp(12)),
              child: SizedBox(
                height: widget.thumbnailHeight,
                width: double.infinity,
                child: widget.thumbnail,
              ),
            ),
            SizedBox(height: gap),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TitleMarquee(title: widget.title),
                    if (widget.subtitle != null) ...[
                      SizedBox(height: smallGap),
                      BodySmall(widget.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis,isMarquee: true,),
                    ],
                  ],
                ),
              ),
              if (widget.isPremium)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: r.rSp(8), vertical: r.rSp(4)),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(r.rSp(8)),
                  ),
                  child: Caption('Premium', style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          if (widget.progress != null && widget.progress! >= 0 && widget.progress! <= 1) ...[
            SizedBox(height: gap),
            ClipRRect(
              borderRadius: BorderRadius.circular(r.rSp(4)),
              child: LinearProgressIndicator(
                value: widget.progress,
                backgroundColor: colors.dividerColor,
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                minHeight: 6,
              ),
            ),
          ],
          if (widget.child != null) ...[SizedBox(height: gap), widget.child!],
        ],
      ),
    );

    if (widget.onTap == null) return content;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? _kTapScale : 1.0,
        duration: const Duration(milliseconds: 100),
        child: content,
      ),
    );
  }
}
