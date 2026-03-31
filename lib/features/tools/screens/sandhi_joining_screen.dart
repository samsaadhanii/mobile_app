import 'package:flutter/material.dart';

import '../../../Constants/constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/widgets/encoding_picker.dart';
import '../../../shared/widgets/result_card.dart';
import '../../../shared/widgets/sanskrit_input.dart';
import '../../../web_api.dart';

class SandhiJoiningScreen extends StatefulWidget {
  const SandhiJoiningScreen({super.key});

  @override
  State<SandhiJoiningScreen> createState() => _SandhiJoiningScreenState();
}

class _SandhiJoiningScreenState extends State<SandhiJoiningScreen> {
  final _word1Controller = TextEditingController(text: 'लक्ष्मीवान्');
  final _word2Controller = TextEditingController(text: 'शुभलक्षणः');
  String _inputEncoding = Const.UNICODE_DEVANAGARI;
  String _outputEncoding = Const.outputEncodingList[0];
  bool _isLoading = false;
  bool _hasQueried = false;
  List<dynamic> _results = [];

  @override
  void dispose() {
    _word1Controller.dispose();
    _word2Controller.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final w1 = _word1Controller.text.trim();
    final w2 = _word2Controller.text.trim();
    if (w1.isEmpty || w2.isEmpty) return;
    setState(() {
      _isLoading = true;
      _hasQueried = true;
    });

    final results = await WebAPI.sandhiRequest(
      input1: w1,
      input2: w2,
      inEncoding: Const.encodingAbbreviation(_inputEncoding),
      outEncoding: Const.encodingAbbreviation(_outputEncoding),
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _results = results;
    });
  }

  Widget? get _resultChild {
    if (!_hasQueried) return null;
    if (_results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No sandhi forms found.'),
      );
    }
    return Column(
      children: _results
          .map((item) => _SandhiResultCard(item: item as Map))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: const GradientAppBar(title: 'Sandhi Joining'),
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
                      controller: _word1Controller,
                      label: 'First Word',
                      hint: 'e.g. लक्ष्मीवान्',
                    ),
                    const SizedBox(height: 12),
                    SanskritInput(
                      controller: _word2Controller,
                      label: 'Second Word',
                      hint: 'e.g. शुभलक्षणः',
                      onSubmitted: (_) => _join(),
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
            // ── Join button ───────────────────────────────────────────
            GradientButton(
              label: 'Join',
              icon: Icons.merge_type,
              onPressed: _isLoading ? null : _join,
            ),
            const SizedBox(height: 20),
            // ── Results ───────────────────────────────────────────────
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

// ── Sandhi result card ─────────────────────────────────────────────────────

class _SandhiResultCard extends StatelessWidget {
  const _SandhiResultCard({required this.item});
  final Map item;

  @override
  Widget build(BuildContext context) {
    final w1 = item['word1']?.toString() ?? '';
    final w2 = item['word2']?.toString() ?? '';
    final joined = item['saMhiwapaxam']?.toString() ?? '';
    final type = item['sanXiH']?.toString() ?? '';
    final sutra = item['sUwram']?.toString() ?? '';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.primary.withAlpha(60)),
      ),
      color: Colors.teal.shade50,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Joined form ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    joined,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                          fontSize: 18,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // ── Constituent words ────────────────────────────────────
            Text(
              '$w1  +  $w2',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            // ── Sandhi type ──────────────────────────────────────────
            if (type.isNotEmpty) ...[
              const SizedBox(height: 4),
              _LabelRow(label: 'sandhi', value: type),
            ],
            // ── Sutra ────────────────────────────────────────────────
            if (sutra.isNotEmpty) ...[
              const SizedBox(height: 2),
              _LabelRow(label: 'sūtram', value: sutra),
            ],
          ],
        ),
      ),
    );
  }
}

class _LabelRow extends StatelessWidget {
  const _LabelRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey.shade500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
      ],
    );
  }
}
