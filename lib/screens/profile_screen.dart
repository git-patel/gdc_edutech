import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../app_state.dart';
import '../services/firebase_service.dart';
import '../services/local_storage.dart';
import '../services/onboarding_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/widgets.dart';
import 'admin/admin_dashboard_screen.dart';
import 'onboarding_screen.dart';

/// Me / Profile tab – profile, progress, settings, theme, logout.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

const List<String> _boards = ['CBSE', 'ICSE', 'State', 'Others'];
const List<String> _standards = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
const List<String> _goals = ['School exams', 'Olympiads', 'JEE/NEET', 'General knowledge'];
const List<String> _mediums = ['English', 'Gujarati', 'Hindi'];

class _ProfileScreenState extends State<ProfileScreen> {
  String? _role;
  String? _name;
  String _board = '';
  String _standard = '';
  String _goal = '';
  String _medium = '';
  String _childName = '';
  String? _photoUrl;
  bool _isAdmin = false;
  bool _notificationsEnabled = true;
  int _streak = 0;
  double _overallMastery = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadStreakAndMastery();
  }

  Future<void> _loadProfile() async {
    final role = await OnboardingStorage.getRole();
    final profile = await OnboardingStorage.getProfile();
    debugPrint('[HGP] ProfileScreen _loadProfile from storage role=$role profile=$profile');
    if (mounted) {
      setState(() {
        _role = role;
        _name = profile['name'];
        if (_name != null && _name!.trim().isEmpty) _name = null;
        _board = profile['board'] ?? '';
        _standard = profile['standard'] ?? '';
        _goal = profile['goal'] ?? '';
        _medium = profile['medium'] ?? '';
        _childName = profile['childName'] ?? '';
        _photoUrl = null;
      });
    }
    final user = FirebaseService.auth.currentUser;
    debugPrint('[HGP] ProfileScreen currentUser=${user?.uid} email=${user?.email}');
    if (user != null) {
      if (mounted) setState(() => _photoUrl = user.photoURL ?? _photoUrl);
      final localEmpty = (_name == null || _name!.trim().isEmpty) && _board.isEmpty && _standard.isEmpty;
      debugPrint('[HGP] ProfileScreen localEmpty=$localEmpty → ${localEmpty ? "will try Firestore fallback" : "using local"}');
      if (mounted && localEmpty) {
        final doc = await FirebaseService.getUserDocument(user.uid);
        debugPrint('[HGP] ProfileScreen Firestore fallback doc=${doc != null ? "hasData" : "null"}');
        if (doc != null && mounted) {
          final name = doc['name']?.toString() ?? user.displayName ?? user.email ?? '';
          final board = doc['board']?.toString() ?? '';
          final standard = doc['standard']?.toString() ?? '';
          final goal = doc['goal']?.toString() ?? '';
          final medium = doc['medium']?.toString() ?? '';
          final childName = doc['childName']?.toString() ?? '';
          final roleFromDoc = doc['role']?.toString() ?? role ?? 'student';
          final photoUrl = doc['photoUrl']?.toString();
          setState(() {
            _role = roleFromDoc;
            _name = name.trim().isEmpty ? null : name.trim();
            _board = board;
            _standard = standard;
            _goal = goal;
            _medium = medium;
            _childName = childName;
            if (photoUrl != null && photoUrl.isNotEmpty) _photoUrl = photoUrl;
          });
          await OnboardingStorage.completeOnboarding(
            role: roleFromDoc,
            name: name.trim().isEmpty ? 'User' : name.trim(),
            board: board,
            standard: standard,
            goal: goal,
            medium: medium,
            childNameValue: childName.isEmpty ? null : childName,
          );
          await OnboardingStorage.setUserUid(user.uid);
        }
      }
      final isAdmin = await FirebaseService.isCurrentUserAdmin();
      if (mounted) setState(() => _isAdmin = isAdmin);
    }
  }

  Future<void> _loadStreakAndMastery() async {
    final streak = await LocalStorage.getCurrentStreak();
    final mastery = await LocalStorage.getOverallMastery();
    if (mounted) {
      setState(() {
        _streak = streak;
        _overallMastery = mastery;
      });
    }
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
  }

  String _roleLabel() {
    if (_role == null) return 'User';
    return _role == 'student' ? 'Student' : 'Parent';
  }

  String _goalMotivation(String goal) {
    final g = goal.toLowerCase();
    if (g.contains('jee') || g.contains('neet')) {
      return 'Consistent practice and revision will take you there. You\'ve got this!';
    }
    if (g.contains('olympiad')) {
      return 'Curiosity and problem-solving are your superpowers. Keep exploring!';
    }
    if (g.contains('school')) {
      return 'Small steps every day build strong foundations. Stay curious!';
    }
    return 'Learning is a journey. Enjoy every step you take.';
  }

  void _showThemeDialog() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    showDialog<void>(
      context: context,
      builder: (context) => ValueListenableBuilder<ThemeMode>(
        valueListenable: themeModeNotifier,
        builder: (context, current, _) {
          return AlertDialog(
            title: const SectionTitle('Theme'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _themeOption('System', ThemeMode.system, current),
                _themeOption('Light', ThemeMode.light, current),
                _themeOption('Dark', ThemeMode.dark, current),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: BodyText('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _themeOption(String label, ThemeMode mode, ThemeMode current) {
    final isSelected = current == mode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: BodyText(label),
        trailing: isSelected ? Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.primary) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          themeModeNotifier.value = mode;
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _name ?? '');
    var board = _board.isEmpty ? _boards.first : _board;
    var standard = _standard.isEmpty ? _standards.first : _standard;
    var goal = _goal.isEmpty ? _goals.first : _goal;
    var medium = _medium.isEmpty ? _mediums.first : _medium;
    if (!_boards.contains(board)) board = _boards.first;
    if (!_standards.contains(standard)) standard = _standards.first;
    if (!_goals.contains(goal)) goal = _goals.first;
    if (!_mediums.contains(medium)) medium = _mediums.first;

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final dropdownDecoration = InputDecoration(
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
            ),
          );
          return AlertDialog(
            title: const SectionTitle('Edit Profile'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    controller: nameController,
                    label: 'Name',
                    hint: 'Your name',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: board,
                    decoration: dropdownDecoration,
                    items: _boards.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                    onChanged: (v) => setDialogState(() => board = v ?? board),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: standard,
                    decoration: dropdownDecoration,
                    items: _standards.map((s) => DropdownMenuItem(value: s, child: Text('Class $s'))).toList(),
                    onChanged: (v) => setDialogState(() => standard = v ?? standard),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: goal,
                    decoration: dropdownDecoration,
                    items: _goals.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (v) => setDialogState(() => goal = v ?? goal),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: medium,
                    decoration: dropdownDecoration,
                    items: _mediums.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setDialogState(() => medium = v ?? medium),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const BodyText('Cancel'),
              ),
              PrimaryButton(
                text: 'Save',
                size: ButtonSize.small,
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    AppToast.show(context, message: 'Please enter your name', type: ToastType.error);
                    return;
                  }
                  await OnboardingStorage.updateProfile(name: name, board: board, standard: standard, goal: goal, medium: medium);
                  nameController.dispose();
                  if (!mounted) return;
                  Navigator.pop(context);
                  await _loadProfile();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const SectionTitle('Log out'),
        content: const BodyText('Are you sure? You will need to sign in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const BodyText('Cancel'),
          ),
          PrimaryButton(
            text: 'Log out',
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance.signOut();
                await GoogleSignIn().signOut();
              } catch (_) {}
              await OnboardingStorage.clearOnboarding();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (context) => const OnboardingScreen()),
                (route) => false,
              );
            },
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return MySafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header (photo from Firebase Auth or Firestore, else initials)
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: colors.primaryContainer,
                    backgroundImage: (_photoUrl != null && _photoUrl!.isNotEmpty)
                        ? NetworkImage(_photoUrl!)
                        : null,
                    child: (_photoUrl == null || _photoUrl!.isEmpty)
                        ? Text(
                            _initials(_name),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  AppTitle(_name ?? 'User'),
                  const SizedBox(height: 8),
                  Subtitle(
                    '${_roleLabel()} • Class ${_standard.isEmpty ? "?" : _standard} • ${_board.isEmpty ? "?" : _board}${_medium.isNotEmpty ? " • $_medium" : ""}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Your Goal (motivation)
            if (_goal.isNotEmpty) ...[
              SectionTitle('Your Goal: $_goal'),
              const SizedBox(height: 8),
              BodyText(
                _goalMotivation(_goal),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],

            // 2. Child's profile (if parent)
            if (_role?.toLowerCase() == 'parent' && (_childName.isNotEmpty || _board.isNotEmpty || _standard.isNotEmpty)) ...[
              const SectionTitle("Child's Profile"),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_childName.isNotEmpty) ...[BodyText('Name: $_childName'), const SizedBox(height: 8)],
                    if (_board.isNotEmpty) ...[BodyText('Board: $_board'), const SizedBox(height: 8)],
                    if (_standard.isNotEmpty) ...[BodyText('Class: $_standard'), const SizedBox(height: 8)],
                    if (_goal.isNotEmpty) ...[BodyText('Goal: $_goal'), const SizedBox(height: 8)],
                    if (_medium.isNotEmpty) BodyText('Medium: $_medium'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 3. Progress summary (real streak + overall mastery from storage)
            const SectionTitle('Progress'),
            const SizedBox(height: 12),
            Row(
              children: [
                StreakBadge(streak: _streak, size: StreakBadgeSize.medium),
                const SizedBox(width: 24),
                Column(
                  children: [
                    MasteryRing(progress: _overallMastery, size: 56, showLabel: true),
                    const SizedBox(height: 8),
                    const BodyText('Overall Mastery'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 4. Settings list
            const SectionTitle('Settings'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.dividerColor),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const BodyText('Theme'),
                    subtitle: ValueListenableBuilder<ThemeMode>(
                      valueListenable: themeModeNotifier,
                      builder: (context, mode, _) {
                        final label = switch (mode) {
                          ThemeMode.system => 'System',
                          ThemeMode.light => 'Light',
                          ThemeMode.dark => 'Dark',
                        };
                        return Caption(label);
                      },
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _showThemeDialog,
                  ),
                  Divider(height: 1, color: colors.dividerColor),
                  ListTile(
                    title: const BodyText('Change Class / Board'),
                    subtitle: const Caption('Edit profile'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _showEditProfileDialog,
                  ),
                  Divider(height: 1, color: colors.dividerColor),
                  ListTile(
                    title: const BodyText('Notifications'),
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (v) => setState(() => _notificationsEnabled = v),
                    ),
                  ),
                  Divider(height: 1, color: colors.dividerColor),
                  ListTile(
                    title: const BodyText('Clear cache'),
                    subtitle: const Caption('Free up space'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cache cleared (dummy)')),
                      );
                    },
                  ),
                  if (_isAdmin) ...[
                    Divider(height: 1, color: colors.dividerColor),
                    ListTile(
                      title: BodyText('Admin Panel', style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600)),
                      subtitle: const Caption('Manage subjects, chapters, contents'),
                      trailing: Icon(Icons.admin_panel_settings_rounded, color: colors.primary),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const AdminDashboardScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                  Divider(height: 1, color: colors.dividerColor),
                  ListTile(
                    title: BodyText('Log out', color: colors.error),
                    trailing: Icon(Icons.logout_rounded, color: colors.error),
                    onTap: _showLogoutDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
