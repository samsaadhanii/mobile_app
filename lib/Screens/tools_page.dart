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
                title: const Text('Morphological Analyser ',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios),
                subtitle: const Text('(शब्द-विश्लेषक)',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Noun Generator ',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios),
                subtitle: const Text('(नामरूप-निष्पादिका)',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Verb Generator ',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios),
                subtitle: const Text('(क्रियारूप-निष्पादिका)',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Sandhi Joining ',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios),
                subtitle: const Text('(सन्धि)',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Sandhi Analyser ',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios),
                subtitle: const Text('(सन्धि-विच्छेद)',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Dhātupāṭhaḥ ',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios),
                subtitle: const Text('(धातुपाठः)',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
