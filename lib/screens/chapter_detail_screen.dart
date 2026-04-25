import 'package:flutter/material.dart';

import '../services/local_storage.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import '../widgets/widgets.dart';
import 'content_viewer_screen.dart';
import 'mindmap_viewer_screen.dart';
import 'coming_soon_screen.dart';
import 'quiz_screen.dart';
import 'audio_player_screen.dart';

import 'ai_tutor_screen.dart';

/// Main hub when user taps a chapter: progress, content grid, actions.
class ChapterDetailScreen extends StatefulWidget {
  const ChapterDetailScreen({
    super.key,
    required this.chapterTitle,
    required this.chapterId,
    required this.overallProgress,
    this.subjectName,
    this.estimatedMinutes = 45,
    this.nextChapterTitle,
  });

  final String chapterTitle;
  final String chapterId;
  final double overallProgress;
  final String? subjectName;
  final int estimatedMinutes;
  final String? nextChapterTitle;

  @override
  State<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends State<ChapterDetailScreen> {
  double? _quizMastery;
  double? _audioProgress;

  @override
  void initState() {
    super.initState();
    _loadQuizMastery();
    _loadAudioProgress();
  }

  Future<void> _loadQuizMastery() async {
    final mastery = await LocalStorage.getMasteryForChapter(widget.chapterId);
    if (mounted) setState(() => _quizMastery = mastery);
  }

  Future<void> _loadAudioProgress() async {
    final progress = await LocalStorage.getAudioProgress(widget.chapterId);
    if (mounted) setState(() => _audioProgress = progress);
  }

  /// Dummy content items for "Available Content" grid (6 items). Progress/subtitle hardcoded.
  static List<Map<String, dynamic>> _contentItems(String chapterTitle, String chapterId) {
    return [
      {'key': 'mindmap', 'title': 'Mind Map', 'subtitle': 'Visual summary', 'icon': Icons.map_rounded, 'progress': 0.0},
      {'key': 'notes', 'title': 'Notes (PDF)', 'subtitle': 'Chapter notes', 'icon': Icons.picture_as_pdf_rounded, 'progress': 0.65},
      {'key': 'video', 'title': 'Video Lesson', 'subtitle': 'Watch explanation', 'icon': Icons.play_circle_rounded, 'progress': 0.4},
      {'key': 'audio', 'title': 'Audio Explanation', 'subtitle': 'Listen anytime', 'icon': Icons.mic_rounded, 'progress': 0.0},
      {'key': 'text', 'title': 'Text / HTML Lesson', 'subtitle': 'Read the lesson', 'icon': Icons.article_rounded, 'progress': 0.0},
      {'key': 'quiz', 'title': 'Quiz', 'subtitle': 'Test yourself', 'icon': Icons.quiz_rounded, 'progress': 0.0},
    ];
  }

  void _onContentTap(BuildContext context, String key) {
    switch (key) {
      case 'mindmap':
        Navigator.push(context, MaterialPageRoute<void>(
          builder: (_) => MindmapViewerScreen(
            title: '${widget.chapterTitle} – Mind Map',
            imageUrl: 'https://picsum.photos/800/600?random=mindmap',
          ),
        ));
        break;
      case 'notes':
        Navigator.push(context, MaterialPageRoute<void>(
          builder: (_) => ContentViewerScreen(
            contentType: 'pdf',
            title: '${widget.chapterTitle} – Notes',
            url: ContentViewerDummyUrls.pdf,
            contentId: '${widget.chapterId}_notes',
          ),
        ));
        break;
      case 'video':
        Navigator.push(context, MaterialPageRoute<void>(
          builder: (_) => ContentViewerScreen(
            contentType: 'video',
            title: '${widget.chapterTitle} – Video',
            url: ContentViewerDummyUrls.video,
            contentId: '${widget.chapterId}_video',
          ),
        ));
        break;
      case 'audio':
        Navigator.push(context, MaterialPageRoute<void>(
          builder: (_) => AudioPlayerScreen(
            audioUrl: kDummyAudioUrl,
            title: '${widget.chapterTitle} – Audio',
            chapterId: widget.chapterId,
          ),
        )).then((_) => _loadAudioProgress());
        break;
      case 'text':
        Navigator.push(context, MaterialPageRoute<void>(
          builder: (_) => const ComingSoonScreen(
            title: 'Text Lesson',
            message: 'Rich text lessons are coming soon.',
            icon: Icons.article_rounded,
          ),
        ));
        break;
      case 'quiz':
        Navigator.push(context, MaterialPageRoute<void>(
          builder: (_) => QuizScreen(chapterTitle: widget.chapterTitle, chapterId: widget.chapterId),
        )).then((_) => _loadQuizMastery());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final items = _contentItems(widget.chapterTitle, widget.chapterId);
    final progressPercent = (widget.overallProgress * 100).round();
    final hasProgress = widget.overallProgress > 0;

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.chapterTitle,
        showBackButton: true,
      ),
      body: MySafeArea(
        child: LayoutBuilder(
          builder: (context, _) {
            final r = context;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(r.rW(20), r.rH(16), r.rW(20), r.rH(32)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Sticky-feel top section: progress + CTA ─────────────────
                  Container(
                    padding: EdgeInsets.all(r.rSp(20)),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(r.rSp(20)),
                      border: Border.all(color: colors.dividerColor),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            MasteryRing(
                              progress: widget.overallProgress.clamp(0.0, 1.0),
                              size: r.rSp(72),
                              showLabel: true,
                            ),
                            SizedBox(width: r.rW(16)),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  BodyText(
                                    'Chapter Progress: $progressPercent%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: colors.onSurface,
                                    ),
                                  ),
                                  SizedBox(height: r.rSp(4)),
                                  BodySmall(
                                    'Estimated time: ${widget.estimatedMinutes} min',
                                    style: TextStyle(color: colors.captionColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (hasProgress) ...[
                          SizedBox(height: r.rH(20)),
                          SizedBox(
                            width: double.infinity,
                            child: PrimaryButton(
                              text: 'Continue where you left',
                              onPressed: () => _onContentTap(context, 'notes'),
                              size: ButtonSize.large,
                              icon: Icon(Icons.play_arrow_rounded, size: r.rSp(22)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: r.rH(32)),
                  // ─── Available Content ───────────────────────────────────────
                  SectionTitle('Available Content'),
                  SizedBox(height: r.rH(16)),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: r.rSp(14),
                      crossAxisSpacing: r.rSp(14),
                      childAspectRatio: r.gridChildAspectRatio(crossAxisCount: 2, minHeightFraction: 0.28),
                    ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final key = item['key'] as String;
                  double progress = (item['progress'] as num).toDouble();
                  if (key == 'quiz') progress = _quizMastery ?? 0.0;
                  if (key == 'audio') progress = _audioProgress ?? 0.0;
                  String subtitle = item['subtitle'] as String;
                  if (key == 'audio' && (_audioProgress ?? 0) > 0) {
                    subtitle = 'Listened ${((_audioProgress ?? 0) * 100).round()}%';
                  }
                  return _ContentGridCard(
                    title: item['title'] as String,
                    subtitle: subtitle,
                    icon: item['icon'] as IconData,
                    progress: progress,
                    onTap: () => _onContentTap(context, key),
                    colors: colors,
                  );
                },
              ),
              SizedBox(height: r.rH(28)),
              // ─── Mark complete + Next chapter teaser ─────────────────────
              SecondaryButton(
                text: 'Mark Chapter as Complete',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: BodyText('Chapter marked complete!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: colors.primaryContainer,
                    ),
                  );
                },
                size: ButtonSize.large,
              ),
              if (widget.nextChapterTitle != null && widget.nextChapterTitle!.isNotEmpty) ...[
                SizedBox(height: r.rH(12)),
                Center(
                  child: BodySmall(
                    'Next: ${widget.nextChapterTitle}',
                    style: TextStyle(color: colors.captionColor),
                  ),
                ),
              ],
            ],
          ),
        );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AITutorScreen(
                subjectName: widget.subjectName ?? 'General Subject',
                chapterTitle: widget.chapterTitle,
              ),
            ),
          );
        },
        backgroundColor: colors.primary,
        icon: Icon(Icons.auto_awesome, color: colors.onPrimary),
        label: Text('Learn with AI', style: TextStyle(color: colors.onPrimary, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _ContentGridCard extends StatelessWidget {
  const _ContentGridCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.progress,
    required this.onTap,
    required this.colors,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final double progress;
  final VoidCallback onTap;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final isComplete = progress >= 1.0;
    final actionLabel = isComplete ? 'Completed' : (progress > 0 ? 'Continue' : 'Start');
    final r = context;

    return ContentCard(
      title: title,
      subtitle: subtitle,
      progress: progress > 0 && !isComplete ? progress : null,
      thumbnailHeight: r.rH(56),
      thumbnail: Container(
        decoration: BoxDecoration(
          color: colors.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(r.rSp(12)),
        ),
        child: Icon(icon, size: r.rSp(28), color: colors.primary),
      ),
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (isComplete)
            Container(
              padding: EdgeInsets.symmetric(horizontal: r.rSp(8), vertical: r.rSp(4)),
              decoration: BoxDecoration(
                color: AppColors.successColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(r.rSp(8)),
              ),
              child: Caption(
                actionLabel,
                style: TextStyle(
                  color: AppColors.successColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Caption(
              actionLabel,
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
