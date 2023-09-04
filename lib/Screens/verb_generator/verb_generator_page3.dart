import 'package:flutter/material.dart';

class VerbGeneratorPage3 extends StatefulWidget {
  const VerbGeneratorPage3({
    super.key,
    required this.selectedVerb,
    required this.selectedPrefix,
  });

  final String selectedVerb;
  final String selectedPrefix;

  @override
  State<VerbGeneratorPage3> createState() => _VerbGeneratorPage3State();
}

class _VerbGeneratorPage3State extends State<VerbGeneratorPage3> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Specify the number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Verb Generator'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Passive/Impersonal'),
              Tab(text: 'Causative'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Center(
              child: Text('Active Content'),
            ),
            Center(
              child: Text('Passive/Impersonal Content'),
            ),
            Center(
              child: Text('Causative Content'),
            ),
          ],
        ),
      ),
    );
  }
}
