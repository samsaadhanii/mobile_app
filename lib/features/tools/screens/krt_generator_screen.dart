import 'package:flutter/material.dart';

import '../../../Constants/constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/widgets/encoding_picker.dart';
import '../../../shared/widgets/result_card.dart';
import '../../../shared/widgets/sanskrit_input.dart';
import '../../../web_api.dart';

class KrtGeneratorScreen extends StatefulWidget {
  const KrtGeneratorScreen({super.key});

  @override
  State<KrtGeneratorScreen> createState() => _KrtGeneratorScreenState();
}

class _KrtGeneratorScreenState extends State<KrtGeneratorScreen> {
  // Default dhatu in WX internal format — same as v1 default.
  final _dhatuController = TextEditingController(
    text: 'gam1_gamLz_BvAxiH_gawO',
  );
  final _upasargaController = TextEditingController(text: '-');
  String _outputEncoding = Const.outputEncodingList[0]; // IAST
  bool _isLoading = false;
  bool _hasQueried = false;
  // Grouped: suffix → {form: [...], lifgam: [...]}
  Map<String, Map<String, List<String>>> _tableData = {};

  @override
  void dispose() {
    _dhatuController.dispose();
    _upasargaController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final dhatu = _dhatuController.text.trim();
    if (dhatu.isEmpty) return;
    setState(() {
      _isLoading = true;
      _hasQueried = true;
    });

    final raw = await WebAPI.krtRequest(
      input1: dhatu,
      input3: _upasargaController.text.trim().isEmpty
          ? '-'
          : _upasargaController.text.trim(),
      inEncoding: 'WX',
      outEncoding: Const.verbAPIOutEncodingAbbreviation(_outputEncoding),
    );

    if (!mounted) return;

    // Group by kqw_prawyayaH (suffix).
    final grouped = <String, Map<String, List<String>>>{};
    for (final el in raw) {
      final suffix = el['kqw_prawyayaH']?.toString() ?? '';
      final lifgam = el['lifgam']?.toString() ?? '';
      final form = el['form']?.toString() ?? '';
      grouped.putIfAbsent(suffix, () => {'form': [], 'lifgam': []});
      grouped[suffix]!['form']!.add(form);
      grouped[suffix]!['lifgam']!.add(lifgam);
    }

    setState(() {
      _isLoading = false;
      _tableData = grouped;
    });
  }

  Widget? get _resultChild {
    if (!_hasQueried) return null;
    if (_tableData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No kṛt forms found.'),
      );
    }
    return Column(
      children: _tableData.entries
          .map((e) => _KrtSuffixCard(
                suffix: e.key,
                forms: e.value['form'] ?? [],
                lifgams: e.value['lifgam'] ?? [],
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: const GradientAppBar(title: 'Kṛt Generator'),
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
                      controller: _dhatuController,
                      label: 'Dhātu (WX format)',
                      hint: 'e.g. gam1_gamLz_BvAxiH_gawO',
                    ),
                    const SizedBox(height: 12),
                    SanskritInput(
                      controller: _upasargaController,
                      label: 'Upasarga (optional, use - for none)',
                      hint: 'e.g. pra  or  -',
                      onSubmitted: (_) => _generate(),
                    ),
                    const SizedBox(height: 12),
                    EncodingPicker(
                      label: 'Output Encoding',
                      value: _outputEncoding,
                      options: Const.outputEncodingList,
                      onChanged: (v) {
                        if (v != null) setState(() => _outputEncoding = v);
                      },
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
              title: 'Kṛt Forms',
              isLoading: _isLoading,
              child: _resultChild,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card for one kṛt suffix group ──────────────────────────────────────────

class _KrtSuffixCard extends StatelessWidget {
  const _KrtSuffixCard({
    required this.suffix,
    required this.forms,
    required this.lifgams,
  });
  final String suffix;
  final List<String> forms;
  final List<String> lifgams;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.primary.withAlpha(60)),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Suffix label ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(40),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.secondary.withAlpha(80)),
              ),
              child: Text(
                suffix,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // ── lifgam + form pairs ───────────────────────────────────
            for (int i = 0; i < forms.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        i < lifgams.length ? lifgams[i] : '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        forms[i],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
