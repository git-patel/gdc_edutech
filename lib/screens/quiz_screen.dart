import 'dart:async';

import 'package:flutter/material.dart';

import '../services/local_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/widgets.dart';

/// One MCQ: question, 4 options, correct index (0–3), explanation.
class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}

/// 10 dummy MCQ questions (no instant feedback; feedback only on result screen).
List<QuizQuestion> get dummyQuizQuestions => [
  const QuizQuestion(
    question: 'What is the SI unit of force?',
    options: ['Joule', 'Newton', 'Pascal', 'Watt'],
    correctIndex: 1,
    explanation: 'Force is measured in Newtons (N), named after Isaac Newton.',
  ),
  const QuizQuestion(
    question: 'Which of these is a scalar quantity?',
    options: ['Velocity', 'Speed', 'Acceleration', 'Displacement'],
    correctIndex: 1,
    explanation: 'Speed has only magnitude; velocity has magnitude and direction.',
  ),
  const QuizQuestion(
    question: 'What does the slope of a velocity-time graph represent?',
    options: ['Distance', 'Velocity', 'Acceleration', 'Displacement'],
    correctIndex: 2,
    explanation: 'Slope of v-t graph = change in velocity / time = acceleration.',
  ),
  const QuizQuestion(
    question: 'Newton\'s first law is also known as:',
    options: ['Law of inertia', 'F = ma', 'Action-reaction', 'Law of gravitation'],
    correctIndex: 0,
    explanation: 'First law states that a body remains at rest or in uniform motion unless acted upon by a force.',
  ),
  const QuizQuestion(
    question: 'Which force keeps planets in orbit around the Sun?',
    options: ['Magnetic', 'Gravitational', 'Electrostatic', 'Friction'],
    correctIndex: 1,
    explanation: 'Gravitational attraction between the Sun and planets provides the centripetal force.',
  ),
  const QuizQuestion(
    question: 'Work done is zero when the angle between force and displacement is:',
    options: ['0°', '45°', '90°', '180°'],
    correctIndex: 2,
    explanation: 'W = F·s·cos θ; when θ = 90°, cos 90° = 0, so work is zero.',
  ),
  const QuizQuestion(
    question: 'Kinetic energy of a body depends on:',
    options: ['Only mass', 'Only velocity', 'Mass and velocity', 'Neither'],
    correctIndex: 2,
    explanation: 'KE = (1/2)mv² — it depends on both mass and speed.',
  ),
  const QuizQuestion(
    question: 'Power is the rate of change of:',
    options: ['Force', 'Velocity', 'Work', 'Momentum'],
    correctIndex: 2,
    explanation: 'Power = work done / time = rate of doing work.',
  ),
  const QuizQuestion(
    question: 'The unit of pressure in SI is:',
    options: ['Newton', 'Joule', 'Pascal', 'Watt'],
    correctIndex: 2,
    explanation: 'Pressure = force / area; SI unit is Pascal (Pa).',
  ),
  const QuizQuestion(
    question: 'Momentum is the product of:',
    options: ['Force and time', 'Mass and velocity', 'Mass and acceleration', 'Force and distance'],
    correctIndex: 1,
    explanation: 'Momentum p = mass × velocity (p = mv).',
  ),
];

/// Chapter quiz: no instant feedback; all feedback on result screen.
class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.chapterTitle,
    required this.chapterId,
  });

  final String chapterTitle;
  final String chapterId;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const int _totalMinutes = 10;
  static const int _totalSeconds = _totalMinutes * 60;

  final List<QuizQuestion> _questions = dummyQuizQuestions;
  int _currentIndex = 0;
  final Map<int, int> _selectedOption = {};
  int _timeRemainingSeconds = _totalSeconds;
  Timer? _timer;
  bool _showResult = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_timeRemainingSeconds > 0) {
          _timeRemainingSeconds--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goNext() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _goPrevious() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  void _submitQuiz() {
    int correct = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selectedOption[i] == _questions[i].correctIndex) correct++;
    }
    final total = _questions.length;
    final mastery = total > 0 ? correct / total : 0.0;
    final percent = (mastery * 100).round();

    LocalStorage.saveMasteryForChapter(widget.chapterId, mastery);
    if (mounted) {
      AppToast.show(
        context,
        message: 'Mastery updated to $percent%',
        type: ToastType.success,
        duration: const Duration(seconds: 2),
      );
      setState(() {
        _score = correct;
        _showResult = true;
        _timer?.cancel();
      });
    }
  }

  void _retryQuiz() {
    setState(() {
      _currentIndex = 0;
      _selectedOption.clear();
      _showResult = false;
      _score = 0;
      _timeRemainingSeconds = _totalSeconds;
      _timer?.cancel();
      _startTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showResult) {
      return _buildResultScreen();
    }
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Quiz: ${widget.chapterTitle}',
        showBackButton: true,
      ),
      body: MySafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTimerRing(),
                    const SizedBox(height: 28),
                    _buildQuestionCard(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerRing() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final value = _timeRemainingSeconds / _totalSeconds;
    final minutes = _timeRemainingSeconds ~/ 60;
    final seconds = _timeRemainingSeconds % 60;

    return Center(
      child: SizedBox(
        width: 96,
        height: 96,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 6,
                backgroundColor: colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _timeRemainingSeconds <= 60 ? colors.error : colors.primary,
                ),
              ),
            ),
            BodyText(
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// During quiz: only highlight selected option (no correct/incorrect, no explanation).
  Widget _buildQuestionCard() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final q = _questions[_currentIndex];
    final selected = _selectedOption[_currentIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BodySmall(
          'Question ${_currentIndex + 1} of ${_questions.length}',
          style: TextStyle(color: colors.captionColor, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        BodyText(
          q.question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        const SizedBox(height: 24),
        ...List.generate(q.options.length, (i) {
          final isSelected = selected == i;
          final borderColor = isSelected ? colors.primary : colors.outline;
          final bgColor = isSelected ? colors.primaryContainer.withValues(alpha: 0.4) : null;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _selectedOption[_currentIndex] = i),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: BodyText(
                    q.options[i],
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomBar() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isLast = _currentIndex == _questions.length - 1;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Caption('${_currentIndex + 1} / ${_questions.length}'),
            const SizedBox(width: 12),
            Expanded(
              child: OutlineButton(
                text: 'Previous',
                onPressed: _currentIndex > 0 ? _goPrevious : null,
                size: ButtonSize.medium,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryButton(
                text: isLast ? 'Submit' : 'Next',
                onPressed: isLast ? _submitQuiz : _goNext,
                size: ButtonSize.medium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Result screen: score, MasteryRing, scrollable review of all questions, then buttons.
  Widget _buildResultScreen() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final total = _questions.length;
    final percent = total > 0 ? (_score / total * 100).round() : 0;
    final mastery = total > 0 ? _score / total : 0.0;
    final isGreat = percent >= 80;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Quiz: ${widget.chapterTitle}',
        showBackButton: true,
      ),
      body: MySafeArea(
        child: Column(
          children: [
            // Score header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                children: [
                  MasteryRing(
                    progress: mastery,
                    size: 100,
                    showLabel: true,
                  ),
                  const SizedBox(height: 20),
                  SectionTitle('$_score / $total ($percent%)'),
                  const SizedBox(height: 8),
                  BodyText(
                    isGreat ? 'Great Job!' : 'Keep Practicing!',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: isGreat ? AppColors.successColor : colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SectionTitle('Review answers'),
            ),
            const SizedBox(height: 12),
            // Scrollable list of all questions with your answer, correct answer, explanation
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final q = _questions[index];
                  final yourIndex = _selectedOption[index];
                  final isCorrect = yourIndex == q.correctIndex;
                  final yourText = yourIndex != null ? q.options[yourIndex] : '(Not answered)';
                  final correctText = q.options[q.correctIndex];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BodyText(
                            '${index + 1}. ${q.question}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          BodySmall(
                            'Your answer:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colors.captionColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          BodyText(
                            yourText,
                            style: TextStyle(
                              color: isCorrect ? AppColors.successColor : colors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          BodySmall(
                            'Correct answer:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colors.captionColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          BodyText(
                            correctText,
                            style: TextStyle(
                              color: AppColors.successColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          BodyText(
                            q.explanation,
                            style: TextStyle(color: colors.onSurface),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Bottom buttons
            Container(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.dividerColor)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        text: 'Review Weak Topics',
                        onPressed: () => Navigator.of(context).pop(true),
                        size: ButtonSize.large,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: SecondaryButton(
                        text: 'Retry Quiz',
                        onPressed: _retryQuiz,
                        size: ButtonSize.large,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
