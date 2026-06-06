import 'package:flutter/material.dart';

/// Temporary page used for modules that will be built in later phases.
/// Keeps the navigation fully wired so the app is runnable end-to-end now.
class PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String note;

  const PlaceholderPage({
    super.key,
    required this.title,
    required this.icon,
    this.note = 'Coming in a later build phase.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(note, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
