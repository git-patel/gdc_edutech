import 'package:flutter/material.dart';

import '../services/onboarding_storage.dart';
import '../utils/responsive.dart';
import '../widgets/widgets.dart';
import 'subject_chapters_screen.dart';

/// My Class tab – structured path (subjects → chapters).
class MyClassScreen extends StatefulWidget {
  const MyClassScreen({super.key});

  @override
  State<MyClassScreen> createState() => _MyClassScreenState();
}

class _MyClassScreenState extends State<MyClassScreen> {
  String _standard = '';
  String _board = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await OnboardingStorage.getProfile();
    if (mounted) {
      setState(() {
        _standard = profile['standard'] ?? '';
        _board = profile['board'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final r = context;

    return MySafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(r.rSp(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title: My Class – Class X CBSE


            // Subjects grid
            SectionTitle(
              _standard.isNotEmpty && _board.isNotEmpty
                  ? 'Subjects for Class $_standard – $_board'
                  : 'My Subjects',
            ),
            SizedBox(height: r.rH(12)),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: r.rSp(12),
              crossAxisSpacing: r.rSp(12),
              childAspectRatio: r.gridChildAspectRatio(crossAxisCount: 2, minHeightFraction: 0.25),
              children: _dummySubjects.map((s) {
                return ContentCard(
                  title: s.title,
                  subtitle: '${s.chapterCount} Chapters',
                  progress: s.progress,
                  thumbnail: Container(
                    color: colors.primaryContainer.withValues(alpha: 0.4),
                    child: Icon(_subjectIcon(s.title), size: r.rSp(32), color: colors.primary),
                  ),
                  thumbnailHeight: r.rH(64),
                  child: BodySmall('${(s.progress * 100).round()}% Complete'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => SubjectChaptersScreen(
                          subjectName: s.title,
                          chapters: _dummyChapters[s.title] ?? [],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _subjectIcon(String title) {
    switch (title) {
      case 'Mathematics':
        return Icons.calculate_rounded;
      case 'Science':
        return Icons.science_rounded;
      case 'English':
        return Icons.menu_book_rounded;
      case 'Social Science':
        return Icons.public_rounded;
      case 'Hindi':
        return Icons.translate_rounded;
      case 'Computer':
        return Icons.computer_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  static final List<({String title, int chapterCount, double progress})> _dummySubjects = [
    (title: 'Mathematics', chapterCount: 14, progress: 0.78),
    (title: 'Science', chapterCount: 16, progress: 0.65),
    (title: 'English', chapterCount: 10, progress: 0.82),
    (title: 'Social Science', chapterCount: 12, progress: 0.55),
    (title: 'Hindi', chapterCount: 10, progress: 0.71),
    (title: 'Computer', chapterCount: 8, progress: 0.90),
  ];

  static const Map<String, List<({String title, String subtitle, double progress, bool hasNotes, bool hasVideo, bool hasQuiz})>> _dummyChapters = {
    'Mathematics': [
      (title: 'Chapter 1: Real Numbers', subtitle: 'Completed • 45 min', progress: 0.85, hasNotes: true, hasVideo: true, hasQuiz: true),
      (title: 'Chapter 2: Polynomials', subtitle: 'Completed • 38 min', progress: 0.92, hasNotes: true, hasVideo: true, hasQuiz: true),
      (title: 'Chapter 3: Pair of Linear Equations', subtitle: 'In progress • 20 min', progress: 0.60, hasNotes: true, hasVideo: true, hasQuiz: false),
      (title: 'Chapter 4: Quadratic Equations', subtitle: 'Not started', progress: 0.0, hasNotes: false, hasVideo: false, hasQuiz: false),
      (title: 'Chapter 5: Arithmetic Progressions', subtitle: 'Not started', progress: 0.0, hasNotes: false, hasVideo: false, hasQuiz: false),
      (title: 'Chapter 6: Triangles', subtitle: 'Not started', progress: 0.0, hasNotes: false, hasVideo: false, hasQuiz: false),
      (title: 'Chapter 7: Coordinate Geometry', subtitle: 'Not started', progress: 0.0, hasNotes: false, hasVideo: false, hasQuiz: false),
      (title: 'Chapter 8: Introduction to Trigonometry', subtitle: 'Not started', progress: 0.0, hasNotes: false, hasVideo: false, hasQuiz: false),
    ],
    'Science': [
      (title: 'Chapter 1: Chemical Reactions', subtitle: 'Completed • 52 min', progress: 0.88, hasNotes: true, hasVideo: true, hasQuiz: true),
      (title: 'Chapter 2: Acids, Bases and Salts', subtitle: 'Completed • 40 min', progress: 0.75, hasNotes: true, hasVideo: true, hasQuiz: true),
      (title: 'Chapter 3: Metals and Non-metals', subtitle: 'In progress • 25 min', progress: 0.45, hasNotes: true, hasVideo: true, hasQuiz: false),
      (title: 'Chapter 4: Life Processes', subtitle: 'Not started', progress: 0.0, hasNotes: false, hasVideo: false, hasQuiz: false),
      (title: 'Chapter 5: Control and Coordination', subtitle: 'Not started', progress: 0.0, hasNotes: false, hasVideo: false, hasQuiz: false),
      (title: 'Chapter 6: Electricity', subtitle: 'Not started', progress: 0.0, hasNotes: false, hasVideo: false, hasQuiz: false),
      (title: 'Chapter 7: Magnetic Effects of Current', subtitle: 'Not started', progress: 0.0, hasNotes: false, hasVideo: false, hasQuiz: false),
      (title: 'Chapter 8: Light – Reflection', subtitle: 'Not started', progress: 0.0, hasNotes: false, hasVideo: false, hasQuiz: false),
    ],
    'English': [
      (title: 'Chapter 1: A Letter to God', subtitle: 'Completed • 30 min', progress: 0.95, hasNotes: true, hasVideo: true, hasQuiz: true),
      (title: 'Chapter 2: Nelson Mandela', subtitle: 'Completed • 35 min', progress: 0.80, hasNotes: true, hasVideo: true, hasQuiz: true),
      (title: 'Chapter 3: Two Stories About Flying', subtitle: 'In progress • 15 min', progress: 0.50, hasNotes: true, hasVideo: false, hasQuiz: false),
      (title: 'Chapter 4: From the Diary of Anne Frank', subtitle: 'Not started', progress: 0.0, hasNotes: false, hasVideo: false, hasQuiz: false),
      (title: 'Chapter 5: The Hundred Dresses', subtitle: 'Not started', progress: 0.0, hasNotes: false, hasVideo: false, hasQuiz: false),
      (title: 'Chapter 6: Glimpses of India', subtitle: 'Not started', progress: 0.0, hasNotes: false, hasVideo: false, hasQuiz: false),
    ],
    'Social Science': [
      (title: 'Chapter 1: The Rise of Nationalism', subtitle: 'Completed • 48 min', progress: 0.72, hasNotes: true, hasVideo: true, hasQuiz: true),
      (title: 'Chapter 2: Nationalism in India', subtitle: 'In progress • 22 min', progress: 0.55, hasNotes: true, hasVideo: true, hasQuiz: false),
      (title: 'Chapter 3: Resources and Development', subtitle: 'Not started', progress: 0.0, hasNotes: false, hasVideo: false, hasQuiz: false),
      (title: 'Chapter 4: Power Sharing', subtitle: 'Not started', progress: 0.0, hasNotes: false, hasVideo: false, hasQuiz: false),
      (title: 'Chapter 5: Federalism', subtitle: 'Not started', progress: 0.0, hasNotes: false, hasVideo: false, hasQuiz: false),
      (title: 'Chapter 6: Democracy and Diversity', subtitle: 'Not started', progress: 0.0, hasNotes: false, hasVideo: false, hasQuiz: false),
    ],
    'Hindi': [
      (title: 'Chapter 1: हरिहर काका', subtitle: 'Completed • 28 min', progress: 0.88, hasNotes: true, hasVideo: true, hasQuiz: true),
      (title: 'Chapter 2: सपनों के से दिन', subtitle: 'In progress • 18 min', progress: 0.40, hasNotes: true, hasVideo: false, hasQuiz: false),
      (title: 'Chapter 3: तोप', subtitle: 'Not started', progress: 0.0, hasNotes: false, hasVideo: false, hasQuiz: false),
      (title: 'Chapter 4: माता का आँचल', subtitle: 'Not started', progress: 0.0, hasNotes: false, hasVideo: false, hasQuiz: false),
      (title: 'Chapter 5: मनुष्यता', subtitle: 'Not started', progress: 0.0, hasNotes: false, hasVideo: false, hasQuiz: false),
    ],
    'Computer': [
      (title: 'Chapter 1: Computer System', subtitle: 'Completed • 35 min', progress: 0.90, hasNotes: true, hasVideo: true, hasQuiz: true),
      (title: 'Chapter 2: Python Basics', subtitle: 'Completed • 42 min', progress: 0.85, hasNotes: true, hasVideo: true, hasQuiz: true),
      (title: 'Chapter 3: Data Handling', subtitle: 'In progress • 20 min', progress: 0.65, hasNotes: true, hasVideo: true, hasQuiz: false),
      (title: 'Chapter 4: Conditional Statements', subtitle: 'Not started', progress: 0.0, hasNotes: false, hasVideo: false, hasQuiz: false),
      (title: 'Chapter 5: Loops', subtitle: 'Not started', progress: 0.0, hasNotes: false, hasVideo: false, hasQuiz: false),
    ],
  };
}
