import 'package:flutter/material.dart';

/// Stands in for a task whose new screen is not built yet.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title, this.message});

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message ?? '$title is being rebuilt and will return in a later release.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
