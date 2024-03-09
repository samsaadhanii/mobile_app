import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class AshtadhyayiSimulation extends StatefulWidget {
  const AshtadhyayiSimulation({Key? key, required this.content})
      : super(key: key);
  final String content;
  @override
  State<AshtadhyayiSimulation> createState() => _AshtadhyayiSimulationState();
}

/// ****************************************************
/// Display the Ashtadhyayi Simulation content in HTML format using
/// flutter_html package
/// This is used in the NounGeneratorScreen to display the Ashtadhyayi
/// content in Android version
/// ****************************************************
class _AshtadhyayiSimulationState extends State<AshtadhyayiSimulation> {
  @override
  Widget build(BuildContext context) {
    // return Html(data: widget.content);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ashtadhyayi Simulation'),
      ),
      body: widget.content.isNotEmpty
          ? SingleChildScrollView(child: Html(data: widget.content))
          : const Center(child: Text('No data available')),
    );
  }
}
