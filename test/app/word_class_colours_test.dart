import 'package:flutter/material.dart' hide Split;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/engine_identity.dart' show contrastRatio;
import 'package:mobile_app/app/settings.dart';
import 'package:mobile_app/app/word_class_colours.dart';
import 'package:mobile_app/core/constants/app_theme.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/features/analyse_word/analysis_card.dart';
import 'package:mobile_app/features/settings/about_page.dart';
import 'package:mobile_app/features/split/split_view.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// U30: the colour of a word class (Heritage's scheme, read from its reader
/// and /DICO/style.css on 4 Nov 2026).
final _themes = {'light': AppTheme.lightTheme, 'dark': AppTheme.darkTheme};

Analysis _a(WordClass c) => Analysis(lemma: const SanskritText('rAma'), wordClass: c);

Future<AppSettings> _settings() async {
  SharedPreferences.setMockInitialValues({'settings.displayScript': 'iast'});
  return AppSettings.load();
}

void main() {
  group('the table', () {
    test('Heritage\'s colours, class by class', () {
      expect(heritageWordClassColour(WordClass.noun), const Color(0xFF00C0FF));
      expect(heritageWordClassColour(WordClass.participle), const Color(0xFF00C0FF));
      expect(heritageWordClassColour(WordClass.verb), const Color(0xFFFF1975));
      expect(heritageWordClassColour(WordClass.indeclinable), const Color(0xFFFF99FF));
      expect(heritageWordClassColour(WordClass.compoundMember), const Color(0xFFFFFF00));
    });

    test('a class without a colour has none', () {
      expect(heritageWordClassColour(WordClass.other), isNull);
      for (final t in _themes.values) {
        expect(wordClassColour(WordClass.other, t.colorScheme), isNull);
      }
    });

    test('noun is blue and verb is red-pink, as in Samsaadhanii\'s skyblue and pink',
        () {
      final noun = HSVColor.fromColor(heritageWordClassColour(WordClass.noun)!);
      final verb = HSVColor.fromColor(heritageWordClassColour(WordClass.verb)!);
      expect(noun.hue, inInclusiveRange(180, 240));
      expect(verb.hue > 320 || verb.hue < 10, isTrue);
    });

    for (final entry in _themes.entries) {
      test('${entry.key}: every border is 3 to 1 against the card', () {
        final scheme = entry.value.colorScheme;
        for (final c in colouredWordClasses) {
          final colour = wordClassColour(c, scheme)!;
          expect(contrastRatio(colour, scheme.surfaceContainerLow),
              greaterThanOrEqualTo(3.0),
              reason: '${entry.key} ${c.name}');
        }
      });
    }

    test('the colours stay apart: the five classes give four different colours',
        () {
      for (final t in _themes.values) {
        final colours = {
          for (final c in colouredWordClasses) wordClassColour(c, t.colorScheme)
        };
        expect(colours.length, 4); // noun and participle share one
      }
    });
  });

  group('the analysis card', () {
    Future<void> pump(WidgetTester tester, Analysis a, ThemeData theme) async {
      final settings = await _settings();
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(body: AnalysisCard(analysis: a, settings: settings)),
      ));
    }

    for (final t in _themes.entries) {
      testWidgets('${t.key}: each class gets its colour as a 4 dp left border',
          (tester) async {
        for (final c in colouredWordClasses) {
          await pump(tester, _a(c), t.value);
          final box = tester.widget<DecoratedBox>(find.byKey(const Key('class-border')));
          final border = (box.decoration as BoxDecoration).border! as Border;
          expect(border.left.width, 4);
          expect(border.left.color, wordClassColour(c, t.value.colorScheme));
          expect(border.top, BorderSide.none);
          expect(border.right, BorderSide.none);
          expect(border.bottom, BorderSide.none);
        }
      });

      testWidgets('${t.key}: the card itself is the theme\'s card colour, '
          'so the contrast test is about the right pair', (tester) async {
        await pump(tester, _a(WordClass.noun), t.value);
        final card = tester.widget<Card>(find.byType(Card));
        expect(card.color, isNull);
        final material = tester.widget<Material>(find
            .descendant(of: find.byType(Card), matching: find.byType(Material))
            .first);
        expect(material.color, t.value.colorScheme.surfaceContainerLow);
      });
    }

    testWidgets('a class without a colour has no border', (tester) async {
      await pump(tester, _a(WordClass.other), AppTheme.lightTheme);
      expect(find.byKey(const Key('class-border')), findsNothing);
      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('Split and analyse', () {
    testWidgets('a square before each word that has a coloured class',
        (tester) async {
      final settings = await _settings();
      const rama = SanskritText('rAma');
      final found = Found(
          WordAnalysis(rama, [_a(WordClass.compoundMember)]),
          ResultSource(engine: EngineId.heritage, program: 'p', time: DateTime.utc(2026)));
      final other = Found(
          WordAnalysis(rama, [_a(WordClass.other)]),
          ResultSource(engine: EngineId.heritage, program: 'p', time: DateTime.utc(2026)));
      final split = Split([
        const Segment(SanskritText('rAma'), Boundary.compound),
        const Segment(SanskritText('Alaya'), Boundary.end),
      ], analyses: [
        found,
        other
      ]);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: SplitView(split: split, settings: settings)),
      ));
      final squares = find.byKey(const Key('class-square'));
      expect(squares, findsOneWidget);
      expect(tester.widget<ColoredBox>(squares).color,
          wordClassColour(WordClass.compoundMember, AppTheme.lightTheme.colorScheme));
    });
  });

  group('About', () {
    testWidgets('lists each class beside its colour', (tester) async {
      PackageInfo.setMockInitialValues(
          appName: 'a', packageName: 'p', version: '1', buildNumber: '1', buildSignature: '');
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(theme: AppTheme.lightTheme, home: const AboutPage()));
      await tester.pumpAndSettle();
      expect(find.text('Colours'), findsOneWidget);
      for (final c in colouredWordClasses) {
        final swatch = find.byKey(Key('colour-${c.name}'));
        expect(swatch, findsOneWidget, reason: c.name);
        expect(tester.widget<ColoredBox>(swatch).color,
            wordClassColour(c, AppTheme.lightTheme.colorScheme));
      }
      expect(find.text('Verb (kriyā)'), findsOneWidget);
      expect(find.text('Compound member (samāsapadam)'), findsOneWidget);
    });
  });
}
