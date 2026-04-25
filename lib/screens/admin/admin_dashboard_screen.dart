import 'package:flutter/material.dart';

import '../../services/firebase_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';
import 'chapter_management_screen.dart';
import 'content_management_screen.dart';
import 'subject_management_screen.dart';

/// Admin dashboard: entry to manage subjects, chapters, contents.
/// Shows loading while checking admin; if not admin, shows empty state and can go back.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final isAdmin = await FirebaseService.isCurrentUserAdmin();
    if (mounted) {
      setState(() {
        _loading = false;
        _isAdmin = isAdmin;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_loading) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Admin Dashboard', showBackButton: true),
        body: const Center(child: LoadingWidget(message: 'Checking access...')),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Admin Dashboard', showBackButton: true),
        body: EmptyState(
          icon: Icons.admin_panel_settings_rounded,
          title: 'Admin access only',
          subtitle: 'You need admin rights to view this section.',
          buttonText: 'Go back',
          onButtonPressed: () => Navigator.of(context).pop(),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(title: 'Admin Dashboard', showBackButton: true),
      body: MySafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionTitle('Manage content'),
            const SizedBox(height: 16),
            _AdminCard(
              title: 'Manage Subjects',
              subtitle: 'Add or edit subjects (e.g. Maths, Science)',
              icon: Icons.subject_rounded,
              colors: colors,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const SubjectManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _AdminCard(
              title: 'Manage Chapters',
              subtitle: 'Add or edit chapters per subject',
              icon: Icons.menu_book_rounded,
              colors: colors,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const ChapterManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _AdminCard(
              title: 'Manage Contents',
              subtitle: 'PDFs, videos, articles, quizzes',
              icon: Icons.library_books_rounded,
              colors: colors,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const ContentManagementScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final ColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.dividerColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: colors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CardTitle(title),
                    const SizedBox(height: 4),
                    BodySmall(subtitle, style: TextStyle(color: colors.onSurface.withValues(alpha: 0.75))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.onSurface),
            ],
          ),
        ),
      ),
    );
  }
}
