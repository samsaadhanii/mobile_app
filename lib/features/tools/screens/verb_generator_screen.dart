import 'package:flutter/material.dart';

import '../../../Constants/constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/widgets/dhatu_picker.dart';
import '../../../shared/widgets/encoding_picker.dart';
import '../../../shared/widgets/result_card.dart';
import '../../../shared/widgets/sanskrit_input.dart';
import '../../../web_api.dart';

class VerbGeneratorScreen extends StatefulWidget {
  const VerbGeneratorScreen({super.key});

  @override
  State<VerbGeneratorScreen> createState() => _VerbGeneratorScreenState();
}

class _VerbGeneratorScreenState extends State<VerbGeneratorScreen> {
  String _selectedDhatuWx = 'gam1_gamLz_BvAxiH_gawO';
  final _upasargaController = TextEditingController(text: '-');
  String _inputEncoding = Const.UNICODE_DEVANAGARI;
  String _outputEncoding = Const.outputEncodingList[0]; // IAST
  bool _isLoading = false;
  bool _hasQueried = false;
  List<dynamic> _results = [];
  String _selectedPadi = Const.ATMANEPADI;

  @override
  void dispose() {
    _upasargaController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final dhatu = _selectedDhatuWx;
    if (dhatu.isEmpty) return;
    setState(() {
      _isLoading = true;
      _hasQueried = true;
    });

    final results = await WebAPI.verbRequest(
      input1: dhatu,
      input2: 'karwari-uBayapaxI',
      input3: _upasargaController.text.trim().isEmpty
          ? '-'
          : _upasargaController.text.trim(),
      inEncoding: Const.encodingAbbreviation(_inputEncoding),
      outEncoding: Const.verbAPIOutEncodingAbbreviation(_outputEncoding),
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
        child: Text('No verb forms found.'),
      );
    }
    final entry = _results[0] as Map;
    final rt = entry['rt']?.toString() ?? '';
    final isAtmane = _selectedPadi == Const.ATMANEPADI;
    final padiKey = isAtmane ? 'Awmane' : 'parasmE';
    final padi = entry[padiKey] as List? ?? [];
    if (padi.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('No $_selectedPadi forms available.'),
      );
    }
    final padData = padi[0] as Map;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Root + padi toggle ───────────────────────────────────────
        if (rt.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              rt,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
            ),
          ),
        // Atmanepadi / Parasmaipadi toggle
        Row(
          children: [
            _PadiChip(
              label: Const.ATMANEPADI,
              selected: _selectedPadi == Const.ATMANEPADI,
              onTap: () => setState(() => _selectedPadi = Const.ATMANEPADI),
            ),
            const SizedBox(width: 8),
            _PadiChip(
              label: Const.PARASMAIPADI,
              selected: _selectedPadi == Const.PARASMAIPADI,
              onTap: () => setState(() => _selectedPadi = Const.PARASMAIPADI),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // ── Lakara tables ────────────────────────────────────────────
        for (int i = 0; i <= 9; i++) ...[
          if (padData['lakAra_$i'] != null) ...[
            _LakaraLabel(label: padData['lakAra_$i'].toString()),
            _FormTable(
              forms: padData['l_forms_$i'] as List? ?? [],
              outputEncoding: _outputEncoding,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: const GradientAppBar(title: 'Verb Generator'),
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
                    DhatuPicker(
                      selectedWx: _selectedDhatuWx,
                      onChanged: (wx) => setState(() => _selectedDhatuWx = wx),
                    ),
                    const SizedBox(height: 12),
                    SanskritInput(
                      controller: _upasargaController,
                      label: 'Upasarga (optional, use - for none)',
                      hint: 'e.g. pra  or  -',
                      onSubmitted: (_) => _generate(),
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ── Generate button ───────────────────────────────────────
            GradientButton(
              label: 'Generate',
              icon: Icons.grid_on,
              onPressed: _isLoading ? null : _generate,
            ),
            const SizedBox(height: 20),
            // ── Results ───────────────────────────────────────────────
            ResultCard(
              title: 'Verb Forms',
              isLoading: _isLoading,
              child: _resultChild,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Padi toggle chip ────────────────────────────────────────────────────────

class _PadiChip extends StatelessWidget {
  const _PadiChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary : Colors.white,
          border: Border.all(
            color: selected ? AppColors.secondary : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

// ── Lakara label ────────────────────────────────────────────────────────────

class _LakaraLabel extends StatelessWidget {
  const _LakaraLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.secondary,
        ),
      ),
    );
  }
}

// ── 3×3 form table for one lakara ───────────────────────────────────────────

class _FormTable extends StatelessWidget {
  const _FormTable({required this.forms, required this.outputEncoding});
  final List forms;
  final String outputEncoding;

  String _get(int i) =>
      i < forms.length ? (forms[i] as Map)['form']?.toString() ?? '' : '';

  @override
  Widget build(BuildContext context) {
    final isDev = outputEncoding == Const.UNICODE_DEVANAGARI;
    final eka = isDev ? 'एकवचनम्' : 'ekavacanam';
    final dvi = isDev ? 'द्विवचनम्' : 'dvivacanam';
    final bah = isDev ? 'बहुवचनम्' : 'bahuvacanam';
    final pra = isDev ? 'प्रथम' : 'prathama';
    final mad = isDev ? 'मध्यम' : 'madhyama';
    final utt = isDev ? 'उत्तम' : 'uttama';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        border: TableBorder.all(color: Colors.grey.shade300),
        columnSpacing: 12,
        horizontalMargin: 8,
        headingRowHeight: 32,
        dataRowMinHeight: 28,
        dataRowMaxHeight: 36,
        headingRowColor:
            WidgetStateProperty.all(AppColors.primary.withAlpha(30)),
        columns: [
          const DataColumn(label: Text('')),
          DataColumn(label: Text(eka, style: const TextStyle(fontSize: 12))),
          DataColumn(label: Text(dvi, style: const TextStyle(fontSize: 12))),
          DataColumn(label: Text(bah, style: const TextStyle(fontSize: 12))),
        ],
        rows: [
          DataRow(cells: [
            DataCell(Text(pra,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12))),
            DataCell(Text(_get(0), style: const TextStyle(fontSize: 12))),
            DataCell(Text(_get(1), style: const TextStyle(fontSize: 12))),
            DataCell(Text(_get(2), style: const TextStyle(fontSize: 12))),
          ]),
          DataRow(cells: [
            DataCell(Text(mad,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12))),
            DataCell(Text(_get(3), style: const TextStyle(fontSize: 12))),
            DataCell(Text(_get(4), style: const TextStyle(fontSize: 12))),
            DataCell(Text(_get(5), style: const TextStyle(fontSize: 12))),
          ]),
          DataRow(cells: [
            DataCell(Text(utt,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12))),
            DataCell(Text(_get(6), style: const TextStyle(fontSize: 12))),
            DataCell(Text(_get(7), style: const TextStyle(fontSize: 12))),
            DataCell(Text(_get(8), style: const TextStyle(fontSize: 12))),
          ]),
        ],
      ),
    );
  }
}
