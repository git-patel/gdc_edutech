import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app_state.dart';
import 'firebase_options.dart';
import 'screens/auth_wrapper.dart';
import 'theme/app_theme.dart';
import 'widgets/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
    // Native side (e.g. Android) already initialized; ignore.
  }
  runApp(const LearnFlowApp());
}

class LearnFlowApp extends StatelessWidget {
  const LearnFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'LearnFlow',
          debugShowCheckedModeBanner: false,
          theme: appLightTheme(),
          darkTheme: appDarkTheme(),
          themeMode: themeMode,
          home: const AuthWrapper(),
        );
      },
    );
  }
}
