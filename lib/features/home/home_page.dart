import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_info.dart';
import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../../sanskrit/transliteration.dart' show toWx;
import '../tools/engine_chips.dart';
import '../tools/tool_entries.dart';
import '../tools/tools_list_page.dart';
import 'dhatu_index.dart';
import 'recent_inputs.dart';
import 'script_detection.dart';
import 'suggestions.dart';

/// Home (`SCREENS.md` section 2): one input box, the detected script, rows
/// for what can be done with the text, recent inputs, and the tools as chips.
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onOpen});

  final OpenTool onOpen;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();

  /// The script the user picked for this input, if they corrected it.
  Script? _override;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DetectedInput _detect(AppSettings settings) {
    final d = detectInput(
      _controller.text,
      fallback: settings.inputScript.script ?? Script.wx,
    );
    return _override == null ? d : DetectedInput(_override!, false, d.words);
  }

  void _open(ToolEntry entry, AppSettings settings) {
    final text = _controller.text.trim();
    if (text.isNotEmpty && settings.keepRecentInputs) {
      context.read<RecentInputs>().add(text);
    }
    widget.onOpen(entry, text);
  }

  Future<void> _pickScript(DetectedInput current) async {
    final picked = await showDialog<Script>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('This input is written in'),
        children: [
          for (final s in Script.values)
            ListTile(
              title: Text(scriptNames[s]!),
              trailing: s == current.script ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, s),
            ),
        ],
      ),
    );
    if (picked != null) setState(() => _override = picked);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final recent = context.watch<RecentInputs>();
    final dhatus = context.watch<DhatuIndex>();
    final theme = Theme.of(context);

    final text = _controller.text;
    final detected = _detect(settings);
    final words = [
      for (final w in text.split(RegExp(r'\s+')))
        if (w.isNotEmpty && RegExp(r'\p{L}', unicode: true).hasMatch(w))
          toWx(w, detected.script),
    ];
    final suggestions = suggestionsFor(words, dhatus: dhatus);

    return Scaffold(
      appBar: AppBar(title: const Text(appDisplayName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 1,
            maxLines: 4,
            style: const TextStyle(fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Type or paste Sanskrit',
              suffixIcon: text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                        _controller.clear();
                        _override = null;
                      }),
                    ),
            ),
            onChanged: (v) => setState(() {
              if (v.isEmpty) _override = null;
            }),
          ),
          if (text.trim().isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _pickScript(detected),
                child: Text(describeDetected(detected)),
              ),
            ),
          for (final s in suggestions)
            Card(
              child: ListTile(
                title: Text(entryFor(s.task).nameEn),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: EngineChips(entryFor(s.task).engines),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(entryFor(s.task), settings),
              ),
            ),
          if (settings.keepRecentInputs && recent.items.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('Recent', style: theme.textTheme.titleSmall),
                ),
                TextButton(
                  onPressed: recent.clear,
                  child: const Text('Clear'),
                ),
              ],
            ),
            for (final item in recent.items)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history, size: 20),
                title: Text(item,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16)),
                onTap: () => setState(() {
                  _controller.text = item;
                  _override = null;
                }),
              ),
          ],
          const SizedBox(height: 16),
          Text('Tools', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final entry in toolEntries)
                ActionChip(
                  label: Text(entry.nameEn),
                  onPressed: () => _open(entry, settings),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
