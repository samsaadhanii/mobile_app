import 'package:flutter/material.dart';

import '../../../Constants/constants.dart';
import '../../../shared/widgets/encoding_picker.dart';
import '../../../shared/widgets/result_card.dart';
import '../../../shared/widgets/sanskrit_input.dart';
import '../../../web_api.dart';

// ── Color helpers ──────────────────────────────────────────────────────────

// Left-border accent and RT text color.
Color _accentColorFor(String? colorStr) {
  switch (colorStr?.toLowerCase().trim()) {
    case 'pink':
      return Colors.pink.shade400;
    case 'skyblue':
    case 'lightblue':
    case 'light blue':
      return Colors.lightBlue.shade500;
    default:
      return Colors.grey.shade400;
  }
}

// Soft card background tint.
Color _bgColorFor(String? colorStr) {
  switch (colorStr?.toLowerCase().trim()) {
    case 'pink':
      return Colors.pink.shade50;
    case 'skyblue':
    case 'lightblue':
    case 'light blue':
      return Colors.lightBlue.shade50;
    default:
      return Colors.white;
  }
}

// Human-readable type label shown in the chip. Null → no chip.
String? _labelFor(String? colorStr) {
  switch (colorStr?.toLowerCase().trim()) {
    case 'pink':
      return 'verb';
    case 'skyblue':
    case 'lightblue':
    case 'light blue':
      return 'noun';
    default:
      return null;
  }
}

// ── ANS parser ─────────────────────────────────────────────────────────────
// Input:  "{prayogaḥ:kartari}{lakāraḥ:laṭ}{puruṣaḥ:prathama}"
// Output: [MapEntry("prayogaḥ", "kartari"), ...]
List<MapEntry<String, String>> _parseAns(String ans) {
  if (ans.isEmpty) return [];
  final matches = RegExp(r'\{([^}]+)\}').allMatches(ans);
  if (matches.isEmpty) return [MapEntry(ans, '')]; // fallback: plain string
  return matches.map((m) {
    final content = m.group(1) ?? '';
    final sep = content.indexOf(':');
    if (sep == -1) return MapEntry(content, '');
    return MapEntry(
      content.substring(0, sep).trim(),
      content.substring(sep + 1).trim(),
    );
  }).toList();
}

// ── Screen ─────────────────────────────────────────────────────────────────

/// v2 Morphological Analyser screen.
///
/// API: morfword={word}&encoding={enc}&outencoding={IAST|DEV}&mode=json
/// Response: List of { 'RT': root, 'ANS': analysis, 'COLOR': colorHint }
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

  Widget? get _resultChild {
    if (!_hasQueried) return null;
    if (_results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No analysis found for the given word.'),
      );
    }
    return Column(
      children: _results
          .map((item) => _ResultItemCard(item: item as Map))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Morphological Analyser'),
        backgroundColor: Colors.grey.shade50,
        surfaceTintColor: Colors.transparent,
      ),
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
                side: BorderSide(color: Colors.grey.shade300),
              ),
              color: Colors.white,
              child: Padding(
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
                              if (v != null) {
                                setState(() => _inputEncoding = v);
                              }
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
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _isLoading ? null : _analyse,
              icon: const Icon(Icons.search),
              label: const Text('Analyse'),
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

// ── Result item card ───────────────────────────────────────────────────────

class _ResultItemCard extends StatelessWidget {
  const _ResultItemCard({required this.item});

  final Map item;

  @override
  Widget build(BuildContext context) {
    final rt = item['RT']?.toString() ?? '';
    final ans = item['ANS']?.toString() ?? '';
    final colorKey = item['COLOR']?.toString();

    final accentColor = _accentColorFor(colorKey);
    final bgColor = _bgColorFor(colorKey);
    final label = _labelFor(colorKey);
    final attrs = _parseAns(ans);

    return Card(
      clipBehavior: Clip.antiAlias,
      color: bgColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: accentColor.withAlpha(60)),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Colored left accent bar.
            Container(width: 4, color: accentColor),
            // Content.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header: RT title + type chip ─────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            rt,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                  fontSize: 18,
                                ),
                          ),
                        ),
                        if (label != null) ...[
                          const SizedBox(width: 8),
                          _TypeChip(label: label, accentColor: accentColor),
                        ],
                      ],
                    ),
                    // ── Attribute rows ────────────────────────────────
                    if (attrs.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...attrs.map((attr) => _AttrRow(attr: attr)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Type chip (e.g. "verb" / "noun") ──────────────────────────────────────

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.accentColor});

  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accentColor.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: accentColor,
        ),
      ),
    );
  }
}

// ── Two-column attribute row (key : value) ─────────────────────────────────

class _AttrRow extends StatelessWidget {
  const _AttrRow({required this.attr});

  final MapEntry<String, String> attr;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key — muted, left column.
          SizedBox(
            width: 110,
            child: Text(
              attr.key,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ),
          // Value — bold, primary color, right column.
          Expanded(
            child: Text(
              attr.value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
