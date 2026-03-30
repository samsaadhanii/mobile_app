import 'package:flutter/material.dart';

import '../../../Constants/constants.dart';
import '../../../shared/widgets/encoding_picker.dart';
import '../../../shared/widgets/result_card.dart';
import '../../../shared/widgets/sanskrit_input.dart';
import '../../../web_api.dart';

/// v2 Morphological Analyser screen.
///
/// API: morfword={word}&encoding={enc}&outencoding={IAST|DEV}&mode=json
/// Response: List of { 'RT': rootString, 'ANS': analysisString }
class MorphAnalyserScreen extends StatefulWidget {
  const MorphAnalyserScreen({super.key});

  @override
  State<MorphAnalyserScreen> createState() => _MorphAnalyserScreenState();
}

class _MorphAnalyserScreenState extends State<MorphAnalyserScreen> {
  final _wordController = TextEditingController(text: 'रामः');

  // Local encoding state — no global variable dependency.
  String _inputEncoding = Const.UNICODE_DEVANAGARI;
  String _outputEncoding = Const.outputEncodingList[0]; // IAST(Roman Diacritic)

  bool _isLoading = false;
  bool _hasQueried = false;
  List<dynamic> _results = [];

  @override
  void dispose() {
    _wordController.dispose();
    super.dispose();
  }

  Future<void> _analyse() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasQueried = true;
    });

    // Convert human-readable encoding labels to API abbreviations.
    // morphAnalyser takes 'Unicode'/'WX'/... for input and 'IAST'/'DEV' for output.
    final inEnc = Const.encodingAbbreviation(_inputEncoding);
    final outEnc = Const.morphOutEncodingAbbreviation(_outputEncoding);

    final results = await WebAPI.morphAnalyser(
      input1: word,
      inEncoding: inEnc,
      outEncoding: outEnc,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _results = results;
    });
  }

  // Returns the widget to pass as ResultCard.child:
  //   null          → ResultCard shows its own "Submit a query…" empty state
  //   Text widget   → "No analysis found" (queried but API returned nothing)
  //   DataTable     → full results
  Widget? get _resultChild {
    if (!_hasQueried) return null;
    if (_results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No analysis found for the given word.'),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        columns: const [
          DataColumn(label: Text('Root (RT)', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Analysis (ANS)', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: _results.map((item) {
          final map = item as Map;
          return DataRow(cells: [
            DataCell(Text(map['RT']?.toString() ?? '')),
            DataCell(Text(map['ANS']?.toString() ?? '')),
          ]);
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Morphological Analyser'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SanskritInput(
              controller: _wordController,
              label: 'Input Word',
              hint: 'e.g. रामः  or  rAmaH',
              onSubmitted: (_) => _analyse(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: EncodingPicker(
                    label: 'Input Encoding',
                    value: _inputEncoding,
                    options: Const.inputEncodingList,
                    onChanged: (v) {
                      if (v != null) setState(() => _inputEncoding = v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: EncodingPicker(
                    label: 'Output Encoding',
                    value: _outputEncoding,
                    options: Const.outputEncodingList,
                    onChanged: (v) {
                      if (v != null) setState(() => _outputEncoding = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _analyse,
                child: const Text('Analyse'),
              ),
            ),
            const SizedBox(height: 20),
            ResultCard(
              title: 'Results',
              isLoading: _isLoading,
              child: _resultChild,
            ),
          ],
        ),
      ),
    );
  }
}
