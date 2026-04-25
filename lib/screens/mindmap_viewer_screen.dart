import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/widgets.dart';

/// Full-screen image viewer for mind maps: pinch zoom, pan.
class MindmapViewerScreen extends StatelessWidget {
  const MindmapViewerScreen({
    super.key,
    required this.title,
    required this.imageUrl,
    this.imageUrls,
  });

  final String title;
  /// Single image URL (used if [imageUrls] is null).
  final String imageUrl;
  /// Optional list for gallery swipe; if set, [imageUrl] is ignored for display.
  final List<String>? imageUrls;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final urls = imageUrls ?? [imageUrl];

    return Scaffold(
      appBar: CustomAppBar(
        title: title,
        showBackButton: true,
      ),
      body: MySafeArea(
        child: PageView.builder(
          itemCount: urls.length,
          itemBuilder: (context, index) {
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  urls[index],
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                              strokeWidth: 3,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          BodySmall(
                            'Loading image...',
                            style: TextStyle(color: colors.captionColor),
                          ),
                        ],
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return EmptyState(
                      icon: Icons.image_not_supported_rounded,
                      title: 'Could not load image',
                      subtitle: 'Check your connection or try again.',
                      buttonText: 'Go back',
                      onButtonPressed: () => Navigator.of(context).pop(),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
