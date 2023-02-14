import 'package:flutter/material.dart';
import 'package:mobile_app/Screens/side_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      // body: const Center(child: Text('Home Page')),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              RichText(
                text: const TextSpan(
                  text: '   Saṃsādhanī is a computational platform developed '
                      'at the Department of Sanskrit studies for Sanskrit language '
                      'processing. \n\n'
                      'It hosts several computational tools such as'
                      ' morphological analyser, morphological generator, sandhi '
                      'analysis and generation modules, and a dependency parser and'
                      ' Sanskrit-Hindi Machine Translation system.',
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 18,
                    fontWeight: FontWeight.normal,
                    fontStyle: FontStyle.normal,
                    fontFamily: 'oswald',
                  ),
                ),
              ),
              // RichText(
              //   text: const TextSpan(
              //     text: '   Sanskrit is the primary culture-bearing language '
              //         'of India. We have witnessed a continuous production'
              //         ' of literature in Sanskrit in all fields of human'
              //         ' endeavour for several thousands of years.',
              //     style: TextStyle(
              //       color: Colors.grey,
              //       fontSize: 20,
              //       fontWeight: FontWeight.bold,
              //       fontStyle: FontStyle.italic,
              //     ),
              //   ),
              // ),
              // RichText(
              //   text: const TextSpan(
              //     text: '   During the past few decades, there has been an '
              //         'emerging trend among Indians to learn Sanskrit to read'
              //         ' and understand these original Sanskrit texts, '
              //         'especially the philosophical, mathematical and '
              //         'Āyurvedic manuscripts. Despite having a very well '
              //         'defined grammar, one finds it challenging to understand '
              //         'Sanskrit texts due to the complexity involved in'
              //         ' compound word-formation in Sanskrit, euphonic changes '
              //         'due to the influence of oral tradition, and the tendency'
              //         ' to use long compound expressions without word breaks.',
              //     style: TextStyle(
              //       color: Colors.grey,
              //       fontSize: 20,
              //       fontWeight: FontWeight.bold,
              //       fontStyle: FontStyle.italic,
              //     ),
              //   ),
              // ),
              Container()
            ],
          ),
        ),
      ),
      drawer: const SideDrawer(),
    );
  }
}
