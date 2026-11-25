import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/features/gita_page/gita_page_screen.dart';
import 'package:mobile_app/features/read/read_page.dart';

/// Stands in for the WebView, which cannot run in widget tests.
class _FakeView implements GitaPageView {
  _FakeView(this.events);
  final GitaPageEvents events;
  int goBacks = 0;
  int reloads = 0;
  bool canGoBack = false;

  @override
  Widget build(BuildContext context) => const SizedBox(key: Key('fake-web'));

  @override
  Future<bool> goBack() async {
    goBacks++;
    if (canGoBack) {
      canGoBack = false;
      events.onHistory(false);
      return true;
    }
    return false;
  }

  @override
  Future<void> reload() async => reloads++;
}

// The progress bar never settles while the page loads, so these tests pump for
// a fixed time instead of pumpAndSettle.
void main() {
  _FakeView? view;
  GitaPageView factory(GitaPageEvents e) => view = _FakeView(e);

  Future<void> pumpRead(WidgetTester tester) async {
    view = null;
    await tester.pumpWidget(MaterialApp(home: ReadPage(gitaViewFactory: factory)));
  }

  testWidgets('the Read tab has its title and the Gītā card with its credit',
      (tester) async {
    await pumpRead(tester);
    expect(find.text('Read'), findsOneWidget);
    expect(find.byType(Card), findsOneWidget);
    expect(find.text('Bhagavad Gītā'), findsOneWidget);
    expect(find.text('भगवद्गीता'), findsOneWidget);
    expect(find.text('Page by Sarath Oruganti'), findsOneWidget);
  });

  testWidgets('the card opens the Gītā screen with its title and credit',
      (tester) async {
    await pumpRead(tester);
    await tester.tap(find.byType(Card));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(GitaPageScreen), findsOneWidget);
    expect(find.byKey(const Key('fake-web')), findsOneWidget);
    final bar = find.byType(AppBar);
    expect(find.descendant(of: bar, matching: find.text('Bhagavad Gītā')),
        findsOneWidget);
    expect(find.descendant(of: bar, matching: find.text('Page by Sarath Oruganti')),
        findsOneWidget);
  });

  testWidgets('a progress bar while loading; a message and Retry on failure',
      (tester) async {
    await pumpRead(tester);
    await tester.tap(find.byType(Card));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    // Loading until the page says otherwise.
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    view!.events.onFinished();
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsNothing);

    view!.events.onFailed();
    await tester.pump();
    expect(find.textContaining('could not be loaded'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(view!.reloads, 1);
    expect(find.text('Retry'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('back goes back in the page first, then leaves the screen',
      (tester) async {
    await pumpRead(tester);
    await tester.tap(find.byType(Card));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    view!.canGoBack = true;
    view!.events.onHistory(true);
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(view!.goBacks, 1);
    expect(find.byType(GitaPageScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(GitaPageScreen), findsNothing);
    expect(find.byType(ReadPage), findsOneWidget);
  });

  test('only this site is followed inside the WebView', () {
    expect(gitaPageAllows('https://1amongus.github.io/BG-1/'), isTrue);
    expect(gitaPageAllows('https://1amongus.github.io/BG-1/kriyapada-quiz.html'),
        isTrue);
    expect(gitaPageAllows('about:blank'), isTrue);
    expect(
        gitaPageAllows(
            'https://ereaders.samsaadhanii.in/books/ereaders/#/read/shrimadbhagavadgita/1-1-1'),
        isFalse);
    expect(gitaPageAllows('http://1amongus.github.io/BG-1/'), isFalse);
    expect(gitaPageAllows('https://1amongus.github.io.evil.example/'), isFalse);
    expect(gitaPageUrl, startsWith('https://$gitaPageHost/'));
  });
}
