import 'package:flutter/material.dart';

import '../services/local_storage.dart';
import '../services/onboarding_storage.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import '../widgets/app_toast.dart';
import '../widgets/widgets.dart';
import 'chapter_detail_screen.dart';
import 'content_viewer_screen.dart';
import 'subject_chapters_screen.dart';

/// Home tab – dashboard, today's focus, continue learning, weak areas, subjects, motivation.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _role;
  String? _name;
  String _board = '';
  String _standard = '';
  String _goal = '';
  int _streak = 0;
  final Map<String, double> _masteryByChapter = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _updateStreakAndLoad();
  }

  Future<void> _loadProfile() async {
    final role = await OnboardingStorage.getRole();
    final profile = await OnboardingStorage.getProfile();
    if (mounted) {
      setState(() {
        _role = role;
        _name = profile['name'];
        if (_name != null && _name!.trim().isEmpty) _name = null;
        _board = profile['board'] ?? '';
        _standard = profile['standard'] ?? '';
        _goal = profile['goal'] ?? '';
      });
    }
  }

  Future<void> _updateStreakAndLoad() async {
    await LocalStorage.updateStreak();
    final streak = await LocalStorage.getCurrentStreak();
    final continueIds = _continueLearningDummy.map((e) => e.chapterId).whereType<String>().toList();
    final weakIds = _weakAreasDummy.map((e) => e.chapterId).whereType<String>().toList();
    final allIds = {...continueIds, ...weakIds};
    final Map<String, double> mastery = {};
    for (final id in allIds) {
      mastery[id] = await LocalStorage.getMasteryForChapter(id);
    }
    if (mounted) {
      setState(() {
        _streak = streak;
        _masteryByChapter.addAll(mastery);
      });
    }
  }

  /// Today's focus item based on goal; cycles by day for variety.
  ({String title, String subtitle, double progress, IconData icon}) get _todaysFocus {
    final goal = _goal.toLowerCase();
    final List<({String title, String subtitle, double progress, IconData icon})> items;
    if (goal.contains('jee') || goal.contains('neet')) {
      items = _focusJeeNeet;
    } else if (goal.contains('olympiad')) {
      items = _focusOlympiads;
    } else if (goal.contains('school')) {
      items = _focusSchool;
    } else {
      items = _focusGeneral;
    }
    final index = DateTime.now().day % items.length;
    return items[index];
  }

  static const List<({String title, String subtitle, double progress, IconData icon})> _focusJeeNeet = [
    (title: "Tutor Suggests: Mechanics – Newton's Laws", subtitle: '12 min left', progress: 0.35, icon: Icons.science_rounded),
    (title: "Tutor Suggests: Organic Chemistry – Reactions", subtitle: '15 min left', progress: 0.6, icon: Icons.biotech_rounded),
    (title: "Tutor Suggests: Electrostatics", subtitle: '8 min left', progress: 0.2, icon: Icons.bolt_rounded),
    (title: "Tutor Suggests: Inorganic – Periodic Table", subtitle: '10 min left', progress: 0.5, icon: Icons.table_chart_rounded),
  ];
  static const List<({String title, String subtitle, double progress, IconData icon})> _focusOlympiads = [
    (title: "Tutor Suggests: Problem Solving – Number Theory", subtitle: '20 min', progress: 0.4, icon: Icons.functions_rounded),
    (title: "Tutor Suggests: Biology – Genetics", subtitle: '15 min', progress: 0.55, icon: Icons.eco_rounded),
    (title: "Tutor Suggests: Logical Reasoning", subtitle: '10 min', progress: 0.3, icon: Icons.psychology_rounded),
  ];
  static const List<({String title, String subtitle, double progress, IconData icon})> _focusSchool = [
    (title: "Tutor Suggests: Chapter 3 – Photosynthesis", subtitle: '8 min left', progress: 0.4, icon: Icons.eco_rounded),
    (title: "Tutor Suggests: Algebra – Linear Equations", subtitle: '12 min left', progress: 0.6, icon: Icons.calculate_rounded),
    (title: "Tutor Suggests: Essay Writing", subtitle: '5 min left', progress: 0.75, icon: Icons.edit_note_rounded),
    (title: "Tutor Suggests: Indian History – Freedom Struggle", subtitle: '10 min left', progress: 0.25, icon: Icons.menu_book_rounded),
  ];
  static const List<({String title, String subtitle, double progress, IconData icon})> _focusGeneral = [
    (title: "Tutor Suggests: Quick Revision – Mixed Topics", subtitle: '10 min', progress: 0.5, icon: Icons.auto_stories_rounded),
    (title: "Tutor Suggests: Daily AI Quiz", subtitle: '5 questions', progress: 0.0, icon: Icons.quiz_rounded),
  ];

  /// Opens ChapterDetailScreen for today's focus (relevant chapter).
  void _onTodaysFocusTap(
    BuildContext context,
    ({String title, String subtitle, double progress, IconData icon}) focus,
  ) {
    final chapterTitle = focus.title.replaceFirst("Tutor Suggests: ", "").trim();
    final chapterId = 'today_focus_${focus.title.hashCode.abs()}';
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChapterDetailScreen(
          chapterTitle: chapterTitle,
          chapterId: chapterId,
          overallProgress: focus.progress,
          estimatedMinutes: 45,
        ),
      ),
    );
  }

  /// Opens ContentViewerScreen (PDF) so user can resume from saved position.
  void _onContinueLearningTap(
    BuildContext context,
    ({String title, String subtitle, double progress, String? chapterId}) item,
  ) {
    final contentId = item.chapterId ?? 'continue_${item.title.hashCode}';
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ContentViewerScreen(
          contentType: 'pdf',
          title: item.title,
          url: ContentViewerDummyUrls.pdf,
          contentId: contentId,
        ),
      ),
    );
  }

  /// Opens ChapterDetailScreen for the weak-area chapter with saved mastery.
  void _onWeakAreaTap(
    BuildContext context,
    ({String title, double progress, String? chapterId}) item,
    double progress,
  ) {
    final chapterId = item.chapterId ?? 'weak_${item.title.hashCode}';
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChapterDetailScreen(
          chapterTitle: item.title,
          chapterId: chapterId,
          overallProgress: progress,
          estimatedMinutes: 40,
        ),
      ),
    );
  }

  /// Opens SubjectChaptersScreen with placeholder chapters for the subject.
  void _onSubjectTap(BuildContext context, String subject) {
    final chapters = _subjectChaptersPlaceholder[subject] ?? _defaultPlaceholderChapters(subject);
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SubjectChaptersScreen(
          subjectName: subject,
          chapters: chapters,
        ),
      ),
    );
  }

  /// Shows dialog with full quote; option to go to Library tab.
  void _onMotivationTap(BuildContext context, String quote) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Subtitle('Daily Motivation', style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: BodyText(quote, style: TextStyle(color: colors.onSurface)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: BodyText('OK', style: TextStyle(color: colors.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              AppToast.show(context, message: 'Go to Library tab for more motivation content.', type: ToastType.info);
            },
            child: BodyText('See in Library', style: TextStyle(color: colors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final focus = _todaysFocus;
    final isStudent = _role?.toLowerCase() == 'student';

    final r = context;
    return MySafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(r.rSp(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Role-based greeting (name/role from OnboardingStorage.getProfile)
            AppTitle(isStudent
                ? 'Hi ${_name ?? 'Student'}, ready to learn?'
                : 'Hi ${_name ?? 'Parent'}, track progress'),
            SizedBox(height: r.rH(24)),

            // 1. Hero / Today's Focus (dynamic by goal)
            ContentCard(
              title: focus.title,
              subtitle: focus.subtitle,
              progress: focus.progress,
              thumbnail: Container(
                color: colors.primaryContainer,
                child: Icon(focus.icon, size: 48, color: colors.primary),
              ),
              onTap: () => _onTodaysFocusTap(context, focus),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: 'Start AI Session',
                    onPressed: () => _onTodaysFocusTap(context, focus),
                    size: ButtonSize.small,
                  ),
                ),
              ),
            ),
            SizedBox(height: r.rH(24)),

            // 2. Streak section (real from local storage)
            Row(
              children: [
                StreakBadge(streak: _streak, size: StreakBadgeSize.medium),
                SizedBox(width: r.rW(12)),
                BodyText(_streak > 0 ? 'Keep going!' : 'Start your streak today!'),
              ],
            ),
            Divider(height: r.rSp(32), color: colors.dividerColor, thickness: 1),
            // 3. Continue Learning
            SectionTitle('AI Learning Path'),
            SizedBox(height: r.rH(12)),
            SizedBox(
              height: r.rH(200),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _continueLearningDummy.length,
                separatorBuilder: (context, index) => SizedBox(width: r.rW(12)),
                itemBuilder: (context, index) {
                  final item = _continueLearningDummy[index];
                  final progress = item.chapterId != null && _masteryByChapter.containsKey(item.chapterId)
                      ? _masteryByChapter[item.chapterId]!
                      : item.progress;
                  return SizedBox(
                    height: r.rH(200),
                    width: r.rW(220),
                    child: ContentCard(
                      title: item.title,
                      subtitle: item.subtitle,
                      progress: progress,
                      thumbnailHeight: r.rH(72),
                      thumbnail: Container(
                        color: colors.primaryContainer.withValues(alpha: 0.5),
                        child: Icon(Icons.menu_book_rounded, size: 32, color: colors.primary),
                      ),
                      onTap: () => _onContinueLearningTap(context, item),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: r.rH(24)),

            // 4. Weak Areas
            SectionTitle('AI Identified Weak Areas'),
            SizedBox(height: r.rH(12)),
            ..._weakAreasDummy.map(
              (item) {
                final progress = item.chapterId != null && _masteryByChapter.containsKey(item.chapterId)
                    ? _masteryByChapter[item.chapterId]!
                    : item.progress;
                return Padding(
                  padding: EdgeInsets.only(bottom: r.rSp(10)),
                  child: ContentCard(
                    title: item.title,
                    progress: progress,
                    padding: EdgeInsets.symmetric(horizontal: r.rW(16), vertical: r.rSp(12)),
                    onTap: () => _onWeakAreaTap(context, item, progress),
                  ),
                );
              },
            ),
            Divider(height: r.rSp(32), color: colors.dividerColor, thickness: 1),
            // 5. My Subjects (based on standard – dummy)
            SectionTitle(_standard.isNotEmpty ? 'My Subjects (Class $_standard)' : 'My Subjects'),
            SizedBox(height: r.rH(12)),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: r.rSp(12),
              crossAxisSpacing: r.rSp(12),
              childAspectRatio: r.gridChildAspectRatio(crossAxisCount: 2, minHeightFraction: 0.22),
              children: _subjectsDummy.map((subject) {
                return ContentCard(
                  title: subject,
                  subtitle: _board.isNotEmpty ? _board : 'Subject',
                  thumbnailHeight: r.rH(72),
                  thumbnail: Container(
                    color: colors.secondary.withValues(alpha: 0.2),
                    child: Icon(Icons.school_rounded, size: 36, color: colors.secondary),
                  ),
                  onTap: () => _onSubjectTap(context, subject),
                );
              }).toList(),
            ),
            Divider(height: r.rSp(32), color: colors.dividerColor, thickness: 1),
            // 6. Daily Motivation – swipeable quote
            SectionTitle('Daily Motivation'),
            SizedBox(height: r.rH(12)),
            SizedBox(
              height: r.rH(140),
              child: PageView(
                children: _motivationQuotes.map((quote) {
                  return Padding(
                    padding: EdgeInsets.only(right: r.rW(8)),
                    child: ContentCard(
                      title: quote,
                      padding: EdgeInsets.symmetric(horizontal: r.rW(20), vertical: r.rSp(20)),
                      onTap: () => _onMotivationTap(context, quote),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: r.rH(32)),
          ],
        ),
      ),
    );
  }

  static const List<({String title, String subtitle, double progress, String? chapterId})> _continueLearningDummy = [
    (title: 'Algebra Basics', subtitle: 'Chapter 2', progress: 0.7, chapterId: 'math_algebra_basics'),
    (title: 'Cell Structure', subtitle: 'Science', progress: 0.3, chapterId: 'science_cell_structure'),
    (title: 'Essay Writing', subtitle: 'English', progress: 0.5, chapterId: 'english_essay'),
    (title: 'Indian History', subtitle: 'Social Science', progress: 0.2, chapterId: 'sst_indian_history'),
  ];

  static const List<({String title, double progress, String? chapterId})> _weakAreasDummy = [
    (title: 'Algebra', progress: 0.62, chapterId: 'math_algebra_basics'),
    (title: 'Chemical Reactions', progress: 0.58, chapterId: 'science_chemical_reactions'),
    (title: 'Geometry', progress: 0.65, chapterId: 'math_geometry'),
  ];

  static const List<String> _subjectsDummy = [
    'Maths',
    'Science',
    'English',
    'Social Science',
  ];

  static const List<String> _motivationQuotes = [
    'The expert in anything was once a beginner.',
    'Small steps every day lead to big results.',
    'You are capable of more than you know.',
  ];

  /// Placeholder chapters per subject for SubjectChaptersScreen (Home → My Subjects tap).
  static const Map<String, List<({String title, String subtitle, double progress, bool hasNotes, bool hasVideo, bool hasQuiz})>> _subjectChaptersPlaceholder = {
    'Maths': [
      (title: 'Chapter 1: Real Numbers', subtitle: '45 min', progress: 0.0, hasNotes: true, hasVideo: true, hasQuiz: true),
      (title: 'Chapter 2: Polynomials', subtitle: '38 min', progress: 0.0, hasNotes: true, hasVideo: true, hasQuiz: true),
      (title: 'Chapter 3: Pair of Linear Equations', subtitle: '40 min', progress: 0.0, hasNotes: true, hasVideo: true, hasQuiz: false),
    ],
    'Science': [
      (title: 'Chapter 1: Chemical Reactions', subtitle: '52 min', progress: 0.0, hasNotes: true, hasVideo: true, hasQuiz: true),
      (title: 'Chapter 2: Acids, Bases and Salts', subtitle: '40 min', progress: 0.0, hasNotes: true, hasVideo: true, hasQuiz: true),
      (title: 'Chapter 3: Metals and Non-metals', subtitle: '45 min', progress: 0.0, hasNotes: true, hasVideo: true, hasQuiz: false),
    ],
    'English': [
      (title: 'Chapter 1: A Letter to God', subtitle: '30 min', progress: 0.0, hasNotes: true, hasVideo: true, hasQuiz: true),
      (title: 'Chapter 2: Nelson Mandela', subtitle: '35 min', progress: 0.0, hasNotes: true, hasVideo: true, hasQuiz: true),
    ],
    'Social Science': [
      (title: 'Chapter 1: The Rise of Nationalism', subtitle: '48 min', progress: 0.0, hasNotes: true, hasVideo: true, hasQuiz: true),
      (title: 'Chapter 2: Nationalism in India', subtitle: '42 min', progress: 0.0, hasNotes: true, hasVideo: true, hasQuiz: false),
    ],
  };

  static List<({String title, String subtitle, double progress, bool hasNotes, bool hasVideo, bool hasQuiz})> _defaultPlaceholderChapters(String subject) {
    return [
      (title: '$subject – Chapter 1', subtitle: 'Get started', progress: 0.0, hasNotes: true, hasVideo: true, hasQuiz: true),
    ];
  }
}
