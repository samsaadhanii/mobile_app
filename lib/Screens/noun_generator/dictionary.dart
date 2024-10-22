import 'package:flutter/material.dart';
import '../../widgets/display_dictionary.dart';

class DictionaryPage extends StatefulWidget {
  const DictionaryPage(
      {Key? key, required this.content, required this.inputWord})
      : super(key: key);
  final String content;
  final String inputWord;
  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

/// ****************************************************
/// Display the Dictionary for the given input word in Android version
/// ****************************************************
class _DictionaryPageState extends State<DictionaryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dictionary: ${widget.inputWord}'),
      ),
      body: widget.content.isNotEmpty
          ? DisplayDictionary.displayDictionary(widget.content)
          : const Center(child: Text('No data available')),
    );
  }
}
