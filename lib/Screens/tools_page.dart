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

///************************************************************
/// This is the stateful class for the ToolsPage.
/// This class contains the list of tools available in the app.
/// The tools are listed in the form of cards.
/// Each card has a title, subtitle and a trailing icon.
/// The trailing icon is an arrow icon which navigates to the
/// respective tool page.
/// The tools are:
/// 1. Morphological Analyser
/// 2. Noun Generator
/// 3. Verb Generator
/// 4. Sandhi Joining
/// 5. Sandhi Analyser
/// 6. Dhatupatha
/// 7. Krt Generator
/// ************************************************************
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
            /// Morphological Analyser
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

            /// Noun Generator
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

            /// Verb Generator
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

            /// Sandhi Joining
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

            /// Sandhi Analyser
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

            /// Dhatupatha
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

            /// Krt Generator
            Card(
              child: ListTile(
                title: const Text('Krt Generator ',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios),
                subtitle: const Text('(कृदन्तरूपनिष्पादिका)',
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
