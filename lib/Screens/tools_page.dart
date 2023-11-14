import 'package:flutter/material.dart';

class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Samsaadhanii Tools'),
      ),
      body: SafeArea(
        child: ListView(
          children: <Widget>[
            Card(
              child: ListTile(
                title: const Text('Morphological Analyser (शब्द-विश्लेषक)'),
                trailing: const Icon(Icons.arrow_forward_ios),
                subtitle: const Text(''),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Noun Generator (नामरूप-निष्पादिका)'),
                trailing: const Icon(Icons.arrow_forward_ios),
                subtitle: const Text(''),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Verb Generator (क्रियारूप-निष्पादिका)'),
                trailing: const Icon(Icons.arrow_forward_ios),
                subtitle: const Text(''),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Sandhi Joining (सन्धि)'),
                trailing: const Icon(Icons.arrow_forward_ios),
                subtitle: const Text(''),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Sandhi Analyser (सन्धि-विच्छेद)'),
                trailing: const Icon(Icons.arrow_forward_ios),
                subtitle: const Text(''),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Dhātupāṭhaḥ (धातुपाठः)'),
                trailing: const Icon(Icons.arrow_forward_ios),
                subtitle: const Text(''),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
