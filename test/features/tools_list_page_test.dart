import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/settings.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/features/tools/tool_entries.dart';
import 'package:mobile_app/features/tools/tools_list_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<List<String>> pumpTools(WidgetTester tester,
      {Map<String, Object> prefs = const {}}) async {
    // 640 logical pixels high, as an ordinary phone. The test font draws every
    // glyph as a full-width square, so the width is generous to avoid wrapping
    // that a real font would not do.
    tester.view.physicalSize = const Size(1000, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(prefs);
    final settings = await AppSettings.load();
    final opened = <String>[];
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: settings,
      child: MaterialApp(
        home: ToolsListPage(onOpen: (e, input) => opened.add('${e.nameEn}|$input')),
      ),
    ));
    await tester.pumpAndSettle();
    return opened;
  }

  testWidgets('all eight tools are on screen at once, without scrolling',
      (tester) async {
    await pumpTools(tester);
    for (final e in toolEntries) {
      final row = find.text(e.nameEn);
      expect(row, findsOneWidget, reason: e.nameEn);
      expect(tester.getRect(row).bottom, lessThanOrEqualTo(640),
          reason: e.nameEn);
    }
    expect(toolEntries.length, 8);
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.maxScrollExtent, 0);
  });

  for (final display in DisplayScriptSetting.values) {
    testWidgets('Sanskrit names are Devanagari with ${display.label} display',
        (tester) async {
      await pumpTools(tester,
          prefs: {'settings.displayScript': display.name});
      for (final e in toolEntries) {
        expect(find.text(e.nameSa), findsOneWidget, reason: e.nameSa);
      }
      expect(find.text('धातुपाठः'), findsOneWidget);
      expect(find.text('dhātupāṭhaḥ'), findsNothing);
    });
  }

  testWidgets('group headings are in sentence case', (tester) async {
    await pumpTools(tester);
    for (final g in ['Analysis', 'Generation', 'Reference']) {
      expect(find.text(g), findsOneWidget);
    }
    expect(find.text('ANALYSIS'), findsNothing);
  });

  testWidgets('engines are quiet text, not chips', (tester) async {
    await pumpTools(tester);
    expect(find.byType(Chip), findsNothing);
    expect(find.byType(ActionChip), findsNothing);
    // Both engines for the two analysis rows, one for the rest but Dhātupāṭha.
    expect(find.text('Samsaadhanii · Heritage'), findsNWidgets(2));
    expect(find.text('Samsaadhanii'), findsNWidgets(5));
  });

  testWidgets('a row opens its tool with an empty input', (tester) async {
    final opened = await pumpTools(tester);
    await tester.tap(find.text(Task.dictionary.nameEn));
    expect(opened, ['${Task.dictionary.nameEn}|']);
  });
}
