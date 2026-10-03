import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/features/home/script_detection.dart';

DetectedInput _d(String text, [Script fallback = Script.wx]) =>
    detectInput(text, fallback: fallback);

void main() {
  group('detectInput', () {
    test('any Devanagari letter means Devanagari', () {
      expect(_d('रामः वनं गच्छति'), const DetectedInput(Script.devanagari, true, 3));
      expect(_d('rAma रामः').script, Script.devanagari);
    });

    test('IAST diacritics mean IAST', () {
      expect(_d('rāmaḥ'), const DetectedInput(Script.iast, true, 1));
      expect(_d('saṃskṛtam').script, Script.iast);
      expect(_d('Śiva').script, Script.iast);
      expect(_d('rāma').script, Script.iast); // combining macron
    });

    test('otherwise the settings script, WX by default', () {
      expect(_d('rAmaH vanam'), const DetectedInput(Script.wx, false, 2));
      expect(_d('rAmaH', Script.slp1), const DetectedInput(Script.slp1, false, 1));
    });

    test('Devanagari wins over IAST marks; the text beats the setting', () {
      expect(_d('रामः rāma', Script.slp1).script, Script.devanagari);
      expect(_d('rāma', Script.slp1).script, Script.iast);
    });

    test('daṇḍa and digits are not Devanagari letters', () {
      expect(_d('rAmaH ।').script, Script.wx);
      expect(_d('१२३').script, Script.wx);
    });

    test('word count: pieces with a letter', () {
      expect(_d('').words, 0);
      expect(_d('   ').words, 0);
      expect(_d('rAmaH  vanam gacCawi').words, 3);
      expect(_d('rAmaH 12 ।').words, 1);
    });
  });

  test('describeDetected', () {
    expect(describeDetected(const DetectedInput(Script.devanagari, true, 3)),
        'Devanagari, 3 words');
    expect(describeDetected(const DetectedInput(Script.wx, false, 1)),
        'WX, 1 word');
    expect(describeDetected(const DetectedInput(Script.iast, true, 2)),
        'IAST, 2 words');
  });
}
