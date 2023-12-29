import 'package:flutter/material.dart';
import 'package:mobile_app/Screens/sandhi/sandhi.dart';
import 'package:mobile_app/Screens/sandhi_splitter/sandhi_splitter.dart';
import 'package:mobile_app/Screens/verb_generator/verb_generator_prefixes.dart';

import 'dhatupatha/dhatupatha_page_one.dart';
import 'krt_generator/krt_generator_prefix.dart';
import 'morph_analyser/morph_analyser.dart';
import 'noun_generator/noun_generator.dart';

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
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        return const MorphAnalyser();
                      },
                    ),
                  );
                },
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
                onTap: () => Future.delayed(Duration.zero, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        return const NounGenerator();
                      },
                    ),
                  );
                }),
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
                onTap: () => Future.delayed(Duration.zero, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        return const VerbGeneratorPrefixes();
                      },
                    ),
                  );
                }),
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
                onTap: () => Future.delayed(Duration.zero, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        return const Sandhi();
                      },
                    ),
                  );
                }),
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
                onTap: () => Future.delayed(Duration.zero, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        return const SandhiSplitter();
                      },
                    ),
                  );
                }),
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
                onTap: () => Future.delayed(Duration.zero, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        return const DhatupathaPageOne();
                      },
                    ),
                  );
                }),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Krt Generator ',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios),
                subtitle: const Text('()',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                onTap: () => Future.delayed(Duration.zero, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        return const KrtGeneratorPrefix();
                      },
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
