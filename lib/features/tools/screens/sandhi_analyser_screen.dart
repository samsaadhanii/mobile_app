import 'package:flutter/material.dart';

import '../../../Constants/constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/widgets/encoding_picker.dart';
import '../../../shared/widgets/result_card.dart';
import '../../../shared/widgets/sanskrit_input.dart';
import '../../../web_api.dart';

class SandhiAnalyserScreen extends StatefulWidget {
  const SandhiAnalyserScreen({super.key});

  @override
  State<SandhiAnalyserScreen> createState() => _SandhiAnalyserScreenState();
}

class _SandhiAnalyserScreenState extends State<SandhiAnalyserScreen> {
  final _inputController = TextEditingController(
    text: 'कश्चित्कान्ताविरहगुरुणास्वाधिकारात्प्रमत्तः',
  );
  String _textType = Const.textTypeList[0]; // Sentence
  String _inputEncoding = Const.UNICODE_DEVANAGARI;
  String _outputEncoding = Const.outputEncodingList[0];
  bool _isLoading = false;
  bool _hasQueried = false;
  String _segmentation = '';

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _analyse() async {
    final word = _inputController.text.trim();
    if (word.isEmpty) return;
    setState(() {
      _isLoading = true;
      _hasQueried = true;
    });

    final result = await WebAPI.sandhiSplitter(
      input1: word,
      textType: Const.textTypeAbbreviation(_textType),
      inEncoding: Const.encodingAbbreviation(_inputEncoding),
      outEncoding: Const.outEncodingAbbreviation(_outputEncoding),
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _segmentation = result['segmentation']?.toString() ?? '';
    });
  }

  Widget? get _resultChild {
    if (!_hasQueried) return null;
    if (_segmentation.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No segmentation found.'),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SelectableText(
        _segmentation,
        style: const TextStyle(fontSize: 16, height: 1.7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: const GradientAppBar(title: 'Sandhi Analyser'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Input card ────────────────────────────────────────────
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.primary.withAlpha(80)),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SanskritInput(
                      controller: _inputController,
                      label: 'Input Text',
                      hint: 'e.g. कश्चित्कान्ता...',
                      onSubmitted: (_) => _analyse(),
                    ),
                    const SizedBox(height: 12),
                    EncodingPicker(
                      label: 'Mode',
                      value: _textType,
                      options: Const.textTypeList,
                      onChanged: (v) {
                        if (v != null) setState(() => _textType = v);
                      },
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
                              if (v != null) {
                                setState(() => _outputEncoding = v);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ── Analyse button ────────────────────────────────────────
            GradientButton(
              label: 'Analyse',
              icon: Icons.call_split,
              onPressed: _isLoading ? null : _analyse,
            ),
            const SizedBox(height: 20),
            // ── Results ───────────────────────────────────────────────
            ResultCard(
              title: 'Segmentation',
              isLoading: _isLoading,
              child: _resultChild,
            ),
          ],
        ),
      ),
    );
  }
}
