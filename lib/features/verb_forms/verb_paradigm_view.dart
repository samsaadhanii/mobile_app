import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;

import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../analyse_word/feature_labels.dart';
import 'lakara_table_view.dart';

/// Called when a form is tapped, with the pada it is in.
typedef OnTapPadaForm = void Function(FeatureValue pada, FeatureValue lakara,
    FeatureValue person, FeatureValue number, SanskritText form);

/// The result of Verb forms (`SCREENS.md` 5.4), as a sliver: the heading, then
/// a pada switch (only when more than one pada has forms) and a row of
/// lakāra chips that stay pinned under the top bar while the tables scroll
/// under them, and the lakāras as titled tables. A chip scrolls to its table,
/// leaving the table's heading just below the pinned row. [onKrt] adds the
/// link to the root's kṛt forms at the end.
class VerbParadigmView extends StatefulWidget {
  const VerbParadigmView({
    super.key,
    required this.paradigm,
    required this.settings,
    required this.onTapForm,
    this.onKrt,
  });

  final VerbParadigm paradigm;
  final AppSettings settings;
  final OnTapPadaForm onTapForm;
  final VoidCallback? onKrt;

  @override
  State<VerbParadigmView> createState() => _VerbParadigmViewState();
}

class _VerbParadigmViewState extends State<VerbParadigmView> {
  late FeatureValue _pada = widget.paradigm.padas.first.pada;
  final _keys = [for (final _ in lakaraOrder) GlobalKey()];
  final _pinnedKey = GlobalKey();
  final _switchKey = GlobalKey();
  final _chipsKey = GlobalKey();

  /// The heights of the pinned container and of its two parts, read after they
  /// are laid out (they follow the text size); a guess or null until then.
  double _pinnedHeight = 96;
  double? _switchHeight;
  double? _chipsHeight;

  @override
  void didUpdateWidget(VerbParadigmView old) {
    super.didUpdateWidget(old);
    // A new answer keeps the pada the user was on if it still has forms.
    if (widget.paradigm.pada(_pada) == null) {
      _pada = widget.paradigm.padas.first.pada;
    }
  }

  void _scrollTo(int i) {
    final target = _keys[i].currentContext?.findRenderObject();
    final scrollable = Scrollable.maybeOf(context);
    if (target == null || scrollable == null) return;
    final position = scrollable.position;
    // The pinned block covers the top of the viewport; stop below it. (Null
    // when nothing is pinned.)
    final pinned = (_pinnedKey.currentContext?.size?.height) ?? 0;
    final reveal =
        RenderAbstractViewport.of(target).getOffsetToReveal(target, 0.0).offset;
    position.animateTo(
      (reveal - pinned)
          .clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = widget.settings;
    final script = settings.displayScript.script;
    String label(FeatureValue v) =>
        featureValueLabel(v, language: settings.labelLanguage, display: script);
    final padas = widget.paradigm.padas;
    final shown = widget.paradigm.pada(_pada) ?? padas.first;

    final hasSwitch = padas.length > 1;
    final switchBlock = Padding(
      key: _switchKey,
      padding: const EdgeInsets.only(bottom: 8),
      child: SegmentedButton<FeatureValue>(
        key: const Key('pada-switch'),
        segments: [
          for (final p in padas)
            ButtonSegment(value: p.pada, label: Text(label(p.pada))),
        ],
        selected: {shown.pada},
        onSelectionChanged: (s) => setState(() => _pada = s.first),
      ),
    );
    final chipsBlock = Padding(
      key: _chipsKey,
      padding: const EdgeInsets.only(bottom: 4),
      child: SingleChildScrollView(
        key: const Key('lakara-chips'),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < shown.lakaras.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(label(shown.lakaras[i].lakara),
                      style: const TextStyle(fontSize: 16)),
                  onPressed: () => _scrollTo(i),
                ),
              ),
          ],
        ),
      ),
    );

    // At most a quarter of the visible height (under the top bar) is pinned:
    // switch and chips if both fit in it, else only the chips, else nothing.
    // Measured again whenever the text size or the screen changes.
    final media = MediaQuery.of(context);
    final quarter = (media.size.height - media.padding.top - kToolbarHeight) / 4;
    final chipsH = _chipsHeight ?? 0;
    final switchH = hasSwitch ? (_switchHeight ?? 0) : 0;
    final pinChips = chipsH <= quarter;
    final pinSwitch = hasSwitch && pinChips && switchH + chipsH <= quarter;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pinned = _pinnedKey.currentContext?.size?.height;
      final sw = _switchKey.currentContext?.size?.height;
      final ch = _chipsKey.currentContext?.size?.height;
      bool differs(double? a, double? b) =>
          (a == null) != (b == null) || (a != null && (a - b!).abs() > 0.5);
      if (differs(sw, _switchHeight) ||
          differs(ch, _chipsHeight) ||
          (pinned != null && (pinned - _pinnedHeight).abs() > 0.5)) {
        setState(() {
          _switchHeight = sw ?? _switchHeight;
          _chipsHeight = ch ?? _chipsHeight;
          if (pinned != null) _pinnedHeight = pinned;
        });
      }
    });

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(widget.paradigm.heading.display(script),
                key: const Key('verb-heading'),
                style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary)),
          ),
        ),
        if (hasSwitch && !pinSwitch) SliverToBoxAdapter(child: switchBlock),
        if (pinChips)
          SliverPersistentHeader(
            pinned: true,
            delegate: _PinnedRow(
              height: _pinnedHeight,
              child: Container(
                key: _pinnedKey,
                color: theme.scaffoldBackgroundColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [if (pinSwitch) switchBlock, chipsBlock],
                ),
              ),
            ),
          )
        else
          SliverToBoxAdapter(child: chipsBlock),
        // All tables are built, not lazily, so a chip can find any of them.
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < shown.lakaras.length; i++)
                KeyedSubtree(
                  key: _keys[i],
                  child: LakaraTableView(
                    table: shown.lakaras[i],
                    settings: settings,
                    onTapForm: (lakara, person, number, form) => widget
                        .onTapForm(shown.pada, lakara, person, number, form),
                  ),
                ),
            ],
          ),
        ),
        if (widget.onKrt != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextButton.icon(
                onPressed: widget.onKrt,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Kṛt forms of this root'),
              ),
            ),
          ),
      ],
    );
  }
}

/// Pins [child] at [height]; the child is laid out at its own height, so the
/// owner can measure it.
class _PinnedRow extends SliverPersistentHeaderDelegate {
  _PinnedRow({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: 0,
        maxHeight: double.infinity,
        child: child,
      );

  @override
  bool shouldRebuild(_PinnedRow old) => true;
}
