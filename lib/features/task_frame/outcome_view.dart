import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../tools/tool_entries.dart';

/// "From Samsaadhanii" (wording to be confirmed by both teams, Heritage Q28;
/// `SCREENS.md` section 4). The university is named on the Contributors page
/// only.
const creditLines = {
  EngineId.samsaadhanii: 'From Samsaadhanii',
  EngineId.heritage: 'From the Sanskrit Heritage Platform',
};

class CreditLine extends StatelessWidget {
  const CreditLine(this.source, {super.key});

  final ResultSource source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      creditLines[source.engine]!,
      style: theme.textTheme.bodySmall
          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
    );
  }
}

/// One widget and one wording per `Outcome` (`SCREENS.md` section 4). A null
/// [outcome] is the waiting state. No state is ever a table of dashes or an
/// empty screen.
class OutcomeView<T> extends StatelessWidget {
  const OutcomeView({
    super.key,
    required this.outcome,
    required this.engine,
    required this.builder,
    required this.notFoundTitle,
    required this.onRetry,
    this.other,
    this.onTryOther,
    this.notFoundBody,
    this.notFoundActions = const [],
    this.slowAfter = slowAnswerAfter,
  });

  final Outcome<T>? outcome;

  /// The engine the answer is (or will be) from, for the wording.
  final EngineId engine;

  final Widget Function(T value, ResultSource source) builder;

  /// "No analysis for xyzq": the task's own wording.
  final String notFoundTitle;

  final VoidCallback onRetry;

  /// The other engine, if one can answer this task, and the action to switch.
  final EngineId? other;
  final VoidCallback? onTryOther;

  /// The line under the title; the spelling and script hint when null. A task
  /// whose input is not typed text (a derivation) gives its own, or `''` for
  /// none.
  final String? notFoundBody;

  /// Extra actions for "nothing found" (for example "Split it as a phrase").
  final List<Widget> notFoundActions;

  /// How long the waiting state lasts before it says the server is slow.
  final Duration slowAfter;

  @override
  Widget build(BuildContext context) {
    final o = outcome;
    final name = engineNames[engine]!;
    if (o == null) return _Waiting(name: name, slowAfter: slowAfter);
    final tryOther = other == null || onTryOther == null
        ? null
        : FilledButton.tonal(
            onPressed: onTryOther,
            child: Text('Try ${engineNames[other]!}'),
          );
    final retry = OutlinedButton(onPressed: onRetry, child: const Text('Retry'));

    return switch (o) {
      Found<T>() => builder(o.value, o.source),
      NotFound<T>() => _Message(
          key: const Key('state-notFound'),
          title: notFoundTitle,
          body: notFoundBody ??
              'Check the spelling and the input script (Settings, Input '
                  'script).',
          actions: [if (tryOther != null) tryOther, ...notFoundActions],
        ),
      BadInput<T>() => _Message(
          key: const Key('state-badInput'),
          title: "$name can't use this input.",
          body: o.message.isEmpty
              ? 'Change the input and try again.'
              : '${o.message}. Change the input and try again.',
        ),
      ServerFault<T>() => _Message(
          key: const Key('state-serverFault'),
          title: '$name sent an answer the app can\'t read.',
          actions: [retry, if (tryOther != null) tryOther],
        ),
      Unreachable<T>() => _Message(
          key: const Key('state-unreachable'),
          title: "Can't reach $name.",
          body: 'Check your connection.',
          actions: [retry, if (tryOther != null) tryOther],
        ),
      // Never shown in practice: the engine switch hides an engine that can't
      // answer. Kept so no state is ever blank.
      Unsupported<T>() => _Message(
          key: const Key('state-unsupported'),
          title: "$name can't do this.",
          actions: [if (tryOther != null) tryOther],
        ),
    };
  }
}

/// How long the app waits before saying the server is taking its time. The
/// servers' own time for one request runs from under a second to nine
/// (`WEBSITE-TOOLS.md` F16).
const slowAnswerAfter = Duration(seconds: 4);

/// The progress indicator, and under it, once [slowAfter] has passed, a line
/// saying the engine is slow. It goes with the widget, when the answer or a
/// failure arrives.
class _Waiting extends StatefulWidget {
  const _Waiting({required this.name, required this.slowAfter});

  final String name;
  final Duration slowAfter;

  @override
  State<_Waiting> createState() => _WaitingState();
}

class _WaitingState extends State<_Waiting> {
  Timer? _timer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer(widget.slowAfter, () {
      if (mounted) setState(() => _slow = true);
    });
  }

  /// Another engine is being asked: its wait starts from zero.
  @override
  void didUpdateWidget(_Waiting old) {
    super.didUpdateWidget(old);
    if (old.name != widget.name) {
      _slow = false;
      _start();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: const Key('state-waiting'),
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Center(child: CircularProgressIndicator()),
          if (_slow) ...[
            const SizedBox(height: 16),
            Text(
              '${widget.name} is taking longer than usual.',
              key: const Key('waiting-slow'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({super.key, required this.title, this.body, this.actions = const []});

  final String title;
  final String? body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          if (body != null && body!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(body!),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ],
      ),
    );
  }
}
