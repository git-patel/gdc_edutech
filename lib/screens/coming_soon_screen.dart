import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

/// Placeholder screen for features not yet implemented (e.g. Audio, Text/HTML).
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    required this.title,
    this.message = 'Coming soon.',
    this.icon = Icons.construction_rounded,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: title,
        showBackButton: true,
      ),
      body: MySafeArea(
        child: EmptyState(
          icon: icon,
          title: 'Coming soon',
          subtitle: message,
          buttonText: 'Go back',
          onButtonPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
