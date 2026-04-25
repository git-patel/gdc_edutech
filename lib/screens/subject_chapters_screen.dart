import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/widgets.dart';
import 'chapter_detail_screen.dart';

/// Screen showing chapters for a subject (navigated from My Class).
class SubjectChaptersScreen extends StatelessWidget {
  const SubjectChaptersScreen({
    super.key,
    required this.subjectName,
    required this.chapters,
  });

  final String subjectName;
  final List<({String title, String subtitle, double progress, bool hasNotes, bool hasVideo, bool hasQuiz})> chapters;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Chapters in $subjectName',
        showBackButton: true,
      ),
      body: MySafeArea(
        child: chapters.isEmpty
            ? const EmptyState(icon: Icons.menu_book_rounded, title: 'No chapters yet.')
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: chapters.length,
                itemBuilder: (context, index) {
                  final ch = chapters[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ContentCard(
                      title: ch.title,
                      subtitle: ch.subtitle,
                      progress: ch.progress,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      onTap: () => _onChapterTap(context, ch.title, index, ch.progress),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                ch.hasNotes ? Icons.notes_rounded : Icons.notes_outlined,
                                size: 18,
                                color: ch.hasNotes ? colors.primary : colors.captionColor,
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                ch.hasVideo ? Icons.play_circle_rounded : Icons.play_circle_outline_rounded,
                                size: 18,
                                color: ch.hasVideo ? colors.primary : colors.captionColor,
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                ch.hasQuiz ? Icons.quiz_rounded : Icons.quiz_outlined,
                                size: 18,
                                color: ch.hasQuiz ? colors.primary : colors.captionColor,
                              ),
                            ],
                          ),
                          MasteryRing(progress: ch.progress, size: 44, showLabel: true),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _onChapterTap(
    BuildContext context,
    String chapterTitle,
    int chapterIndex,
    double progress,
  ) {
    final chapters = this.chapters;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ChapterDetailScreen(
          chapterTitle: chapterTitle,
          chapterId: '${subjectName}_${chapterTitle.hashCode}',
          overallProgress: progress,
          subjectName: subjectName,
          estimatedMinutes: 45,
          nextChapterTitle: chapterIndex + 1 < chapters.length
              ? chapters[chapterIndex + 1].title
              : null,
        ),
      ),
    );
  }
}
