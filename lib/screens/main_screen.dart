import 'package:flutter/material.dart';

import '../widgets/widgets.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'my_class_screen.dart';
import 'ai_tutor_screen.dart';
import 'profile_screen.dart';

/// App shell after onboarding: app bar, IndexedStack body, bottom nav.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  static const _titles = ['Home', 'My Class', 'Tutor', 'Library', 'Me'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MySafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: const [
            HomeScreen(),
            MyClassScreen(),
            AITutorScreen(),
            LibraryScreen(),
            ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
