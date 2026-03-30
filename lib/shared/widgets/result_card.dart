import 'package:flutter/material.dart';

/// A card wrapper for displaying tool output.
///
/// Three states:
///   - [isLoading] true  → centered [CircularProgressIndicator]
///   - [child] non-null  → renders the provided widget
///   - both false/null   → shows a clean empty-state message
class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.title,
    this.child,
    this.isLoading = false,
  });

  final String title;
  final Widget? child;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _body(context),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (child != null) {
      return child!;
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Submit a query to see results here.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
        ),
      ),
    );
  }
}