import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/shared/widgets/form_sheet.dart';

Future<void> _open(
  WidgetTester tester, {
  String description = 'tṛtīyā · ekavacanam',
  required List<FormSheetAction> actions,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => showFormSheet(context,
              form: 'rāmeṇa', description: description, actions: actions),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the form, its description and the actions in order',
      (tester) async {
    await _open(tester, actions: [
      FormSheetAction(Icons.format_list_numbered, 'Show derivation', () {}),
      FormSheetAction(Icons.search, 'Analyse this form', () {}),
    ]);
    expect(find.text('rāmeṇa'), findsOneWidget);
    expect(find.text('tṛtīyā · ekavacanam'), findsOneWidget);
    final titles = [
      for (final t in tester.widgetList<ListTile>(find.byType(ListTile)))
        (t.title as Text).data,
    ];
    expect(titles, ['Show derivation', 'Analyse this form']);
  });

  testWidgets('an action closes the sheet, then runs', (tester) async {
    final events = <String>[];
    final observer = _Observer(events);
    await tester.pumpWidget(MaterialApp(
      navigatorObservers: [observer],
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showFormSheet(context,
                form: 'rāmeṇa',
                description: 'd',
                actions: [
                  FormSheetAction(Icons.search, 'Analyse this form',
                      () => events.add('ran')),
                ]),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    events.clear();
    await tester.tap(find.text('Analyse this form'));
    await tester.pumpAndSettle();
    expect(events, ['pop', 'ran']);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('no actions: the form and its description only', (tester) async {
    await _open(tester, actions: const []);
    expect(find.byType(ListTile), findsNothing);
    expect(find.text('rāmeṇa'), findsOneWidget);
  });

  testWidgets('no description: no empty line for it', (tester) async {
    await _open(tester, description: '', actions: const []);
    expect(find.text('rāmeṇa'), findsOneWidget);
    expect(find.text(''), findsNothing);
  });

  testWidgets('the form is large and the description at least 16 sp',
      (tester) async {
    await _open(tester, actions: const []);
    expect(tester.widget<Text>(find.text('rāmeṇa')).style!.fontSize, 28);
    expect(tester.widget<Text>(find.text('tṛtīyā · ekavacanam')).style!.fontSize,
        greaterThanOrEqualTo(16));
  });

  testWidgets('it shows in the dark theme without a fixed colour',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showFormSheet(context,
                form: 'rāmeṇa', description: 'd', actions: const []),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final scheme = ThemeData.dark().colorScheme;
    expect(tester.widget<Text>(find.text('d')).style!.color,
        scheme.onSurfaceVariant);
  });
}

class _Observer extends NavigatorObserver {
  _Observer(this.events);

  final List<String> events;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      events.add('pop');
}
