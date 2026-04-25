import 'dart:async';

import 'package:flutter/material.dart';

import '../services/onboarding_storage.dart';
import '../widgets/widgets.dart';
import 'main_screen.dart';
import 'onboarding_screen.dart';

/// First screen users see. When [autoNavigate] is true (default), after 3s goes to onboarding or main.
/// When false (e.g. used as auth loading placeholder), only shows the splash UI.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.autoNavigate = true});

  final bool autoNavigate;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.autoNavigate) {
      _timer = Timer(const Duration(seconds: 3), _navigate);
    }
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final completed = await OnboardingStorage.isOnboardingCompleted();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => completed ? const MainScreen() : const OnboardingScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: MySafeArea(
        top: true,
        bottom: true,
        backgroundColor: backgroundColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              Icon(
                Icons.school_rounded,
                size: 120,
                color: colors.primary,
              ),
              const SizedBox(height: 32),
              const AppTitle('LearnFlow'),
              const SizedBox(height: 12),
              const Subtitle('Learn without limits'),
              const SizedBox(height: 48),
              LoadingWidget(size: 44, color: colors.primary),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Caption('Version 1.0'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
