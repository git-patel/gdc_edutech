import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import '../services/onboarding_storage.dart';
import 'main_screen.dart';
import 'onboarding_screen.dart';
import 'splash_screen.dart';

/// Decides initial route once at startup. Does NOT rebuild when auth state changes,
/// so Google sign-in on onboarding does not replace the screen or lose state.
/// - If onboarding completed → [MainScreen]
/// - Else → [OnboardingScreen] (user completes flow on same screen, then pushReplacement to Main)
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _loading = true;
  bool _onboardingCompleted = false;

  @override
  void initState() {
    super.initState();
    _resolveInitialScreen();
  }

  /// Resolve once: wait for first auth state + isOnboardingCompleted(). Never runs again.
  Future<void> _resolveInitialScreen() async {
    final results = await Future.wait<dynamic>([
      FirebaseService.auth.authStateChanges().first,
      OnboardingStorage.isOnboardingCompleted(),
    ]);
    final completed = results[1] as bool;
    if (!mounted) return;
    setState(() {
      _loading = false;
      _onboardingCompleted = completed;
    });
    debugPrint('[HGP] AuthWrapper initial resolve: onboardingCompleted=$completed → ${completed ? "MainScreen" : "OnboardingScreen"}');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SplashScreen(autoNavigate: false);
    }
    return _onboardingCompleted ? const MainScreen() : const OnboardingScreen();
  }
}
