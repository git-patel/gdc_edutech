import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import '../services/onboarding_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/widgets.dart';
import 'main_screen.dart';

const int _kPageCount = 4;

/// Onboarding flow: welcome, intro, role, profile setup. Saves to SharedPreferences.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const List<String> boards = ['CBSE', 'ICSE', 'State', 'Others'];
  static const List<String> standards = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
  static const List<String> goals = ['School Exams', 'I love Sports (Cricket)', 'I love Video Games', 'Space & Sci-Fi', 'I love Music'];
  static const List<String> mediums = ['English', 'Gujarati', 'Hindi'];

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

const int _kRolePageIndex = 2;

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _childNameController = TextEditingController();

  int _currentPage = 0;
  String? _selectedRole;
  String _board = 'CBSE';
  String _standard = '5';
  String _goal = 'School Exams';
  String _medium = 'English';
  bool _googleSignInLoading = false;
  /// After Google sign-in, if user doc does not exist we show form with name pre-filled and this true.
  bool _signedInNewUserWaitingProfile = false;
  /// Set when new user after Google; used for displayName fallback and ensureUserDocument.
  User? _currentUserForNewProfile;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _childNameController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (index == _kPageCount - 1 && _selectedRole == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _pageController.animateToPage(
          _kRolePageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentPage = _kRolePageIndex);
        AppToast.show(
          context,
          message: 'Please select Student or Parent to continue',
          position: ToastPosition.bottom,
          type: ToastType.error,
        );
      });
      return;
    }
    setState(() => _currentPage = index);
  }

  void _nextPage() {
    if (_currentPage == _kRolePageIndex && _selectedRole == null) {
      AppToast.show(
        context,
        message: 'Please select Student or Parent to continue',
        position: ToastPosition.bottom,
        type: ToastType.error,
      );
      return;
    }
    if (_currentPage < _kPageCount - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    }
  }

  Future<void> _finishOnboarding() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppToast.show(
        context,
        message: 'Please enter your name',
        position: ToastPosition.bottom,
        type: ToastType.error,
      );
      return;
    }
    final role = _selectedRole ?? 'student';
    final childName = _childNameController.text.trim();
    if (role == 'parent' && childName.isEmpty) {
      AppToast.show(
        context,
        message: 'Please enter your child\'s name',
        position: ToastPosition.bottom,
        type: ToastType.error,
      );
      return;
    }
    await OnboardingStorage.completeOnboarding(
      role: role,
      name: name,
      board: _board,
      standard: _standard,
      goal: _goal,
      medium: _medium,
      childNameValue: role == 'parent' ? childName : null,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (context) => const MainScreen()),
    );
  }

  /// 1. Sign in with Google. 2. If returning user → sync Firestore to local, go Main. 3. If new → pre-fill name, show form; Continue saves.
  Future<void> _signInWithGoogleAndFinish() async {
    setState(() => _googleSignInLoading = true);
    UserCredential? credential;
    try {
      credential = await FirebaseService.signInWithGoogle();
    } finally {
      if (mounted) setState(() => _googleSignInLoading = false);
    }
    if (!mounted) return;
    if (credential == null || credential.user == null) {
      AppToast.show(
        context,
        message: 'Sign in was cancelled or failed. Try again.',
        position: ToastPosition.bottom,
        type: ToastType.error,
      );
      return;
    }

    final user = credential.user!;
    debugPrint('[HGP] Onboarding Google sign-in success uid=${user.uid} email=${user.email} displayName=${user.displayName}');
    final exists = await FirebaseService.userExists(user.uid);
    debugPrint('[HGP] Onboarding userExists(uid)=$exists');

    if (exists) {
      final doc = await FirebaseService.getUserDocument(user.uid);
      final name = doc?['name']?.toString() ?? '';
      final role = doc?['role']?.toString() ?? '';
      final hasValidProfile = name.trim().isNotEmpty || role.trim().isNotEmpty;
      debugPrint('[HGP] Onboarding returning user doc: name="$name" role="$role" hasValidProfile=$hasValidProfile');
      if (doc != null && hasValidProfile && mounted) {
        debugPrint('[HGP] Onboarding treating as RETURNING user → sync to local, MainScreen');
        await OnboardingStorage.completeOnboardingFromFirestore(doc);
        await OnboardingStorage.setUserUid(user.uid);
        if (!mounted) return;
        AppToast.show(
          context,
          message: 'Welcome back!',
          position: ToastPosition.bottom,
          type: ToastType.success,
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (context) => const MainScreen()),
        );
        return;
      }
      debugPrint('[HGP] Onboarding doc empty or invalid → treating as NEW user, show form');
    } else {
      debugPrint('[HGP] Onboarding NEW user (no doc) → show form');
    }

    // New user (or existing doc empty): pre-fill name from Google, show form; user taps Continue to save.
    if (mounted) {
      _nameController.text = user.displayName ?? user.email ?? '';
      setState(() {
        _signedInNewUserWaitingProfile = true;
        _currentUserForNewProfile = user;
      });
      debugPrint('[HGP] Onboarding form shown, waiting for Continue. Pre-filled name=${_nameController.text}');
    }
  }

  /// Complete profile for new user after Google sign-in (form already filled; name optional from displayName).
  Future<void> _completeNewUserProfileAfterGoogle() async {
    final role = _selectedRole ?? 'student';
    final childName = _childNameController.text.trim();
    debugPrint('[HGP] Onboarding _completeNewUserProfileAfterGoogle role=$role childName=$childName');
    if (role == 'parent' && childName.isEmpty) {
      AppToast.show(
        context,
        message: 'Please enter your child\'s name',
        position: ToastPosition.bottom,
        type: ToastType.error,
      );
      return;
    }

    final user = _currentUserForNewProfile;
    if (user == null) {
      debugPrint('[HGP] Onboarding _completeNewUserProfileAfterGoogle ERROR currentUser is null');
      AppToast.show(context, message: 'Session expired. Please sign in again.', position: ToastPosition.bottom, type: ToastType.error);
      return;
    }
    final name = _nameController.text.trim().isEmpty ? (user.displayName ?? user.email ?? 'User') : _nameController.text.trim();
    debugPrint('[HGP] Onboarding saving new user uid=${user.uid} name=$name board=$_board standard=$_standard goal=$_goal medium=$_medium');

    await OnboardingStorage.completeOnboarding(
      role: role,
      name: name,
      board: _board,
      standard: _standard,
      goal: _goal,
      medium: _medium,
      childNameValue: role == 'parent' ? childName : null,
    );
    debugPrint('[HGP] Onboarding completeOnboarding done');
    await OnboardingStorage.setUserUid(user.uid);
    debugPrint('[HGP] Onboarding setUserUid done');
    try {
      await FirebaseService.ensureUserDocument(user.uid, {
        'name': name,
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'role': role,
        'board': _board,
        'standard': _standard,
        'goal': _goal,
        'medium': _medium,
        'childName': role == 'parent' ? childName : '',
      });
      debugPrint('[HGP] Onboarding ensureUserDocument done → MainScreen');
    } catch (e, st) {
      debugPrint('[HGP] Onboarding ensureUserDocument FAILED error=$e');
      debugPrint('[HGP] Onboarding ensureUserDocument stackTrace=$st');
      if (mounted) {
        AppToast.show(
          context,
          message: 'Profile saved locally. Cloud save failed: $e',
          position: ToastPosition.bottom,
          type: ToastType.error,
        );
      }
    }
    if (!mounted) return;
    AppToast.show(
      context,
      message: 'Login successful',
      position: ToastPosition.bottom,
      type: ToastType.success,
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (context) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: MySafeArea(
        backgroundColor: backgroundColor,
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: (_currentPage == _kRolePageIndex && _selectedRole == null)
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                onPageChanged: _onPageChanged,
                children: [
                  _WelcomePage(colors: colors),
                  _IntroPage(colors: colors),
                  _RolePage(selectedRole: _selectedRole, onRoleSelected: (r) => setState(() => _selectedRole = r), colors: colors),
                  _ProfilePage(
                    role: _selectedRole ?? 'student',
                    nameController: _nameController,
                    childNameController: _childNameController,
                    board: _board,
                    standard: _standard,
                    goal: _goal,
                    medium: _medium,
                    onBoardChanged: (v) => setState(() => _board = v ?? _board),
                    onStandardChanged: (v) => setState(() => _standard = v ?? _standard),
                    onGoalChanged: (v) => setState(() => _goal = v ?? _goal),
                    onMediumChanged: (v) => setState(() => _medium = v ?? _medium),
                    colors: colors,
                    nameOptional: _signedInNewUserWaitingProfile,
                  ),
                ],
              ),
            ),
            _buildDots(colors),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: _currentPage == _kPageCount - 1
                  ? _signedInNewUserWaitingProfile
                      ? SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            text: 'Continue',
                            onPressed: _completeNewUserProfileAfterGoogle,
                            size: ButtonSize.large,
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: PrimaryButton(
                                text: 'Sign in with Google',
                                onPressed: _googleSignInLoading ? null : _signInWithGoogleAndFinish,
                                size: ButtonSize.large,
                                isLoading: _googleSignInLoading,
                                icon: _googleSignInLoading ? null : Icon(Icons.g_mobiledata_rounded, color: colors.onPrimary, size: 24),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: SecondaryButton(
                                text: 'Skip for now',
                                onPressed: _googleSignInLoading ? null : _finishOnboarding,
                                size: ButtonSize.large,
                              ),
                            ),
                          ],
                        )
                  : SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        text: _currentPage == 0 ? 'Get Started' : 'Next',
                        onPressed: _nextPage,
                        size: ButtonSize.large,
                      ),
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDots(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_kPageCount, (index) {
          final isActive = index == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: isActive ? 24 : 8,
            decoration: BoxDecoration(
              color: isActive ? colors.primary : colors.dividerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_rounded, size: 120, color: colors.primary),
            const SizedBox(height: 40),
            const AppTitle('Welcome to LearnFlow'),
            const SizedBox(height: 16),
            const Subtitle('Your Agentic AI Tutor', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SectionTitle('Intelligent Learning'),
            const SizedBox(height: 24),
            const BodyText(
              'Adaptive pacing, Socratic sessions, and hyper-personalized analogies built just for you.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RolePage extends StatelessWidget {
  const _RolePage({
    required this.selectedRole,
    required this.onRoleSelected,
    required this.colors,
  });

  final String? selectedRole;
  final ValueChanged<String> onRoleSelected;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SectionTitle('Who are you?'),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: _RoleCard(
                    label: 'Student',
                    icon: Icons.person_rounded,
                    isSelected: selectedRole == 'student',
                    onTap: () => onRoleSelected('student'),
                    colors: colors,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RoleCard(
                    label: 'Parent',
                    icon: Icons.family_restroom_rounded,
                    isSelected: selectedRole == 'parent',
                    onTap: () => onRoleSelected('parent'),
                    colors: colors,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? colors.primaryContainer : colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? colors.primary : colors.dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: isSelected ? colors.primary : colors.onSurface),
              const SizedBox(height: 12),
              Subtitle(label, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? colors.primary : colors.onSurface)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({
    required this.role,
    required this.nameController,
    required this.childNameController,
    required this.board,
    required this.standard,
    required this.goal,
    required this.medium,
    required this.onBoardChanged,
    required this.onStandardChanged,
    required this.onGoalChanged,
    required this.onMediumChanged,
    required this.colors,
    this.nameOptional = false,
  });

  final String role;
  final TextEditingController nameController;
  final TextEditingController childNameController;
  final String board;
  final String standard;
  final String goal;
  final String medium;
  final ValueChanged<String?> onBoardChanged;
  final ValueChanged<String?> onStandardChanged;
  final ValueChanged<String?> onGoalChanged;
  final ValueChanged<String?> onMediumChanged;
  final ColorScheme colors;
  final bool nameOptional;

  @override
  Widget build(BuildContext context) {
    final dropdownDecoration = InputDecoration(
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
    );

    final isStudent = role == 'student';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          SectionTitle(isStudent ? 'Tell us about you' : 'Parent profile'),
          const SizedBox(height: 8),
          BodyText(
            isStudent
                ? 'Tell us your interests so your AI Tutor can use analogies you love!'
                : 'Add your child\'s details to track their progress.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          CustomTextField(
            controller: nameController,
            label: isStudent ? 'Your name' : 'Your name (parent)',
            hint: nameOptional ? 'Pre-filled from Google (optional)' : (isStudent ? 'Your name' : 'Parent or guardian name'),
          ),
          if (nameOptional)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: BodySmall('Name is optional when signed in with Google.', style: TextStyle(color: colors.onSurface.withValues(alpha: 0.7), fontSize: 12)),
            ),
          if (isStudent) ...[
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: board,
              decoration: dropdownDecoration,
              items: OnboardingScreen.boards.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: onBoardChanged,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: medium,
              decoration: dropdownDecoration,
              items: OnboardingScreen.mediums.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: onMediumChanged,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: standard,
              decoration: dropdownDecoration,
              items: OnboardingScreen.standards.map((s) => DropdownMenuItem(value: s, child: Text('Class $s'))).toList(),
              onChanged: onStandardChanged,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: goal,
              decoration: dropdownDecoration,
              items: OnboardingScreen.goals.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: onGoalChanged,
            ),

          ] else ...[
            const SizedBox(height: 24),
            BodySmall('Child student details', style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            CustomTextField(
              controller: childNameController,
              label: 'Child\'s name',
              hint: 'Student\'s name',
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: board,
              decoration: dropdownDecoration,
              items: OnboardingScreen.boards.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: onBoardChanged,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: standard,
              decoration: dropdownDecoration,
              items: OnboardingScreen.standards.map((s) => DropdownMenuItem(value: s, child: Text('Class $s'))).toList(),
              onChanged: onStandardChanged,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: goal,
              decoration: dropdownDecoration,
              items: OnboardingScreen.goals.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: onGoalChanged,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: medium,
              decoration: dropdownDecoration,
              items: OnboardingScreen.mediums.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: onMediumChanged,
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
