import 'package:flutter/material.dart';

import '../../../Constants/constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/widgets/encoding_picker.dart';
import '../../../shared/widgets/result_card.dart';
import '../../../shared/widgets/sanskrit_input.dart';
import '../../../web_api.dart';

class NounGeneratorScreen extends StatefulWidget {
  const NounGeneratorScreen({super.key});

  @override
  State<NounGeneratorScreen> createState() => _NounGeneratorScreenState();
}

class _NounGeneratorScreenState extends State<NounGeneratorScreen> {
  final _stemController = TextEditingController(text: 'राम');
  String _gender = Const.genderList[0];
  String _category = Const.categoryList[0];
  String _inputEncoding = Const.UNICODE_DEVANAGARI;
  String _outputEncoding = Const.outputEncodingList[0];
  bool _isLoading = false;
  bool _hasQueried = false;
  // Formatted data: vibhakti → [label, sg, du, pl]
  Map<String, List<String>> _tableData = {};

  @override
  void dispose() {
    _stemController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final stem = _stemController.text.trim();
    if (stem.isEmpty) return;
    setState(() {
      _isLoading = true;
      _hasQueried = true;
    });

    final raw = await WebAPI.nounGenRequest(
      inputString: stem,
      gender: Const.genderAbbreviation(_gender),
      category: Const.catAbbreviation(_category),
      inEncoding: Const.encodingAbbreviation(_inputEncoding),
      outEncoding: Const.encodingAbbreviation(_outputEncoding),
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _tableData = raw.isEmpty ? {} : _formatData(raw);
    });
  }

  // Mirrors v1 NounGenerator.formatData — groups list by vibhakti × vacana.
  Map<String, List<String>> _formatData(List raw) {
    final curData = <String, List<String>>{};
    final vacanam = <String>[];
    for (final el in raw) {
      if (el['vib'] != null) {
        curData.putIfAbsent(
            el['vib'] as String, () => [el['vib'] as String, '', '', '']);
      }
      if (el['vac'] != null && !vacanam.contains(el['vac'])) {
        vacanam.add(el['vac'] as String);
      }
    }
    for (final el in raw) {
      final key = el['vib'] as String? ?? '';
      if (!curData.containsKey(key)) continue;
      final vac = el['vac']?.toString() ?? '';
      final form = el['form']?.toString() ?? '';
      if (vacanam.isNotEmpty && vac.contains(vacanam[0])) {
        curData[key]![1] = form;
      } else if (vacanam.length > 1 && vac.contains(vacanam[1])) {
        curData[key]![2] = form;
      } else if (vacanam.length > 2 && vac.contains(vacanam[2])) {
        curData[key]![3] = form;
      }
    }
    return curData;
  }

  Widget? get _resultChild {
    if (!_hasQueried) return null;
    if (_tableData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No forms found for the given stem.'),
      );
    }
    final headings = Const.headings(_outputEncoding);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        border: TableBorder.all(color: Colors.grey.shade300),
        columnSpacing: 16,
        horizontalMargin: 12,
        headingRowColor: WidgetStateProperty.all(AppColors.primary.withAlpha(30)),
        columns: [
          const DataColumn(label: Text('')),
          DataColumn(label: Text(headings[0])),
          DataColumn(label: Text(headings[1])),
          DataColumn(label: Text(headings[2])),
        ],
        rows: _tableData.entries.map((e) {
          final v = e.value;
          return DataRow(cells: [
            DataCell(Text(v[0],
                style: const TextStyle(fontWeight: FontWeight.w600))),
            DataCell(Text(v[1])),
            DataCell(Text(v[2])),
            DataCell(Text(v[3])),
          ]);
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: const GradientAppBar(title: 'Noun Generator'),
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
                      controller: _stemController,
                      label: 'Prātipadikam (Stem)',
                      hint: 'e.g. राम',
                      onSubmitted: (_) => _generate(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: EncodingPicker(
                            label: 'Gender',
                            value: _gender,
                            options: Const.genderList,
                            onChanged: (v) {
                              if (v != null) setState(() => _gender = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: EncodingPicker(
                            label: 'Category',
                            value: _category,
                            options: Const.categoryList,
                            onChanged: (v) {
                              if (v != null) setState(() => _category = v);
                            },
                          ),
                        ),
                      ],
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
            // ── Generate button ───────────────────────────────────────
            GradientButton(
              label: 'Generate',
              icon: Icons.grid_on,
              onPressed: _isLoading ? null : _generate,
            ),
            const SizedBox(height: 20),
            // ── Results ───────────────────────────────────────────────
            ResultCard(
              title: 'Noun Forms',
              isLoading: _isLoading,
              child: _resultChild,
            ),
          ],
        ),
      ),
    );
  }
}
