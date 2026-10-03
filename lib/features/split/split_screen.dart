import 'package:flutter/material.dart' hide Split;
import 'package:provider/provider.dart';

import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../compare/compare_split_screen.dart';
import '../task_frame/engine_set.dart';
import '../task_frame/input_parsing.dart';
import '../task_frame/outcome_view.dart';
import '../task_frame/task_controller.dart';
import '../task_frame/task_frame.dart';
import '../tools/tool_entries.dart';
import '../tools/tools_list_page.dart';
import 'split_view.dart';

/// What the screen shows for one engine: the best split with its analyses,
/// and, where the engine gives them, other ways to split.
class SplitResult {
  final Segmentation main;

  /// The other ways to split, when the engine gives them. It is still running
  /// when the best split is shown and completes with an empty list if the call
  /// fails or times out; null for an engine that has none.
  final Future<List<Split>>? others;

  const SplitResult(this.main, [this.others]);
}

/// Asks [engine] for the best split with analyses and, for Heritage, also for
/// its other candidates (its analysing call returns only the best one, and one
/// request cannot return both). Both requests start together: the best split
/// is returned as soon as it arrives, and [SplitResult.others] completes later.
Future<Outcome<SplitResult>> loadSplit(Engine engine, SanskritText text) async {
  final mainRequest = engine.segment(text, analyse: true);
  final othersRequest =
      engine.id == EngineId.heritage ? engine.segment(text) : null;
  // Whatever happens to the second call must never be an unhandled error.
  final guarded = othersRequest?.then<Outcome<Segmentation>?>((o) => o).catchError(
        (Object _) => null,
      );

  final main = await mainRequest;
  if (main is! Found<Segmentation>) {
    return switch (main) {
      NotFound<Segmentation>() => const NotFound(),
      BadInput<Segmentation>(:final message) => BadInput(message),
      ServerFault<Segmentation>(:final detail) => ServerFault(detail),
      Unreachable<Segmentation>(:final detail) => Unreachable(detail),
      Unsupported<Segmentation>(:final engine, :final task) =>
        Unsupported(engine, task),
      Found<Segmentation>() => const NotFound(), // unreachable
    };
  }
  final best = main.value.candidates.first;
  final others = guarded?.then<List<Split>>((all) => all is Found<Segmentation>
      ? [
          for (final c in all.value.candidates)
            if (!_sameCut(c, best)) c,
        ]
      : const []);
  return Found(SplitResult(main.value, others), main.source);
}

bool _sameCut(Split a, Split b) =>
    a.segments.length == b.segments.length &&
    [for (var i = 0; i < a.segments.length; i++) a.segments[i] == b.segments[i]]
        .every((x) => x);

/// Split and analyse (`SCREENS.md` 5.2).
class SplitScreen extends StatefulWidget {
  const SplitScreen({super.key, this.initialInput = '', this.onOpenTool});

  final String initialInput;
  final OpenTool? onOpenTool;

  @override
  State<SplitScreen> createState() => _SplitScreenState();
}

class _SplitScreenState extends State<SplitScreen> {
  late final TextEditingController _text;
  TaskController<SplitResult>? _task;
  late final EngineSet _engines;
  SanskritText _input = const SanskritText('');

  /// The text as the user typed it, for messages (not converted).
  String _typed = '';

  @override
  void initState() {
    super.initState();
    _engines = context.read<EngineSet>();
    final settings = context.read<AppSettings>();
    _text = TextEditingController(text: widget.initialInput.trim());
    final available = _engines.forTask(Task.splitText);
    if (available.isEmpty) return;
    _task = TaskController<SplitResult>(
      available: available,
      preferred: settings.preferredEngine,
      run: (id) => loadSplit(_engines[id]!, _input),
    );
    if (_text.text.isNotEmpty) _submit();
  }

  @override
  void dispose() {
    _task?.dispose();
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    if (_text.text.trim().isEmpty) return;
    _typed = _text.text.trim();
    _input = parseSanskrit(_text.text, context.read<AppSettings>());
    _task?.request();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final task = _task;
    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: Text(Task.splitText.nameEn)),
        body: const Center(child: Text('No engine can do this yet.')),
      );
    }
    return ListenableBuilder(
      listenable: task,
      builder: (context, _) {
        final outcome = task.outcome;
        return TaskFrame(
          title: Task.splitText.nameEn,
          input: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _text,
                  minLines: 1,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(hintText: 'Type or paste Sanskrit'),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _submit(),
                ),
              ),
              IconButton(
                tooltip: 'Split and analyse',
                icon: const Icon(Icons.search),
                onPressed: _submit,
              ),
            ],
          ),
          engines: task.available,
          selected: task.engine,
          onEngineChanged: task.switchTo,
          source: outcome is Found<SplitResult> ? outcome.source : null,
          onCompare: _input.isEmpty
              ? null
              : () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => CompareSplitScreen(text: _input),
                  )),
          result: _input.isEmpty && outcome == null && !task.waiting
              ? const SizedBox.shrink()
              : OutcomeView<SplitResult>(
                  outcome: outcome,
                  engine: task.engine,
                  notFoundTitle: 'No split for $_typed',
                  onRetry: task.request,
                  other: task.other,
                  onTryOther: task.other == null
                      ? null
                      : () => task.switchTo(task.other!),
                  builder: (result, source) => _body(result, settings),
                ),
        );
      },
    );
  }

  Widget _body(SplitResult result, AppSettings settings) {
    final best = result.main.candidates.first;
    final tap = widget.onOpenTool == null
        ? null
        : (Segment s) => widget.onOpenTool!(
              entryFor(Task.analyseWord),
              // Devanagari is the one script Home's detection never misreads.
              s.text.display(Script.devanagari),
            );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SplitView(split: best, settings: settings, onWordTap: tap),
        if (result.others != null)
          FutureBuilder<List<Split>>(
            future: result.others,
            builder: (context, snapshot) {
              // Hidden until the second answer arrives, and for good if it
              // failed or had nothing to add.
              final others = snapshot.data;
              if (others == null || others.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ExpansionTile(
                  key: const Key('other-splits'),
                  tilePadding: EdgeInsets.zero,
                  title: Text('${others.length} other ways to split'),
                  children: [
                    for (final other in others)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SplitView(
                          split: other,
                          settings: settings,
                          onWordTap: tap,
                          withAnalyses: false,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
