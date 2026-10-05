import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/features/settings/about_page.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  Future<void> pump(WidgetTester tester, String packageName) async {
    PackageInfo.setMockInitialValues(
      appName: 'Samsaadhanii',
      packageName: packageName,
      version: '1.0.12',
      buildNumber: '7',
      buildSignature: '',
    );
    await tester.pumpWidget(const MaterialApp(home: AboutPage()));
    await tester.pumpAndSettle();
  }

  testWidgets('the released app shows version and build, no test marker',
      (tester) async {
    await pump(tester, 'com.SanskritStudies.mobile_app');
    expect(find.text('Version 1.0.12 (build 7)'), findsOneWidget);
    expect(find.byKey(const Key('test-build')), findsNothing);
    expect(find.text('Test build'), findsNothing);
  });

  testWidgets('the tester build also says "Test build"', (tester) async {
    await pump(tester, 'com.SanskritStudies.mobile_app.test');
    expect(find.text('Version 1.0.12 (build 7)'), findsOneWidget);
    expect(find.text('Test build'), findsOneWidget);
  });
}
