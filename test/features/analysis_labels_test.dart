import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/settings.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/features/analyse_word/feature_labels.dart';

void main() {
  String label(FeatureValue v, LabelLanguage l, Script s, {bool short = false}) =>
      featureValueLabel(v, language: l, display: s, short: short);

  test('the full name by default, in either language and script', () {
    expect(label(FeatureValue.third, LabelLanguage.sanskrit, Script.iast),
        'prathamapuruṣaḥ');
    expect(label(FeatureValue.third, LabelLanguage.english, Script.iast),
        'third person');
    expect(label(FeatureValue.singular, LabelLanguage.sanskrit, Script.devanagari),
        'एकवचनम्');
  });

  test('short: Sanskrit in the display script, English as it is', () {
    expect(label(FeatureValue.third, LabelLanguage.sanskrit, Script.iast, short: true),
        'pra.');
    expect(label(FeatureValue.third, LabelLanguage.sanskrit, Script.devanagari, short: true),
        'प्र.');
    expect(label(FeatureValue.second, LabelLanguage.sanskrit, Script.devanagari, short: true),
        'म.');
    expect(label(FeatureValue.first, LabelLanguage.sanskrit, Script.devanagari, short: true),
        'उ.');
    expect(label(FeatureValue.singular, LabelLanguage.sanskrit, Script.devanagari, short: true),
        'एक.');
    expect(label(FeatureValue.dual, LabelLanguage.sanskrit, Script.devanagari, short: true),
        'द्वि.');
    expect(label(FeatureValue.plural, LabelLanguage.sanskrit, Script.devanagari, short: true),
        'बहु.');
    expect(label(FeatureValue.third, LabelLanguage.english, Script.devanagari, short: true),
        '3rd');
    expect(label(FeatureValue.dual, LabelLanguage.english, Script.iast, short: true),
        'du.');
  });

  test('the cases have short names too', () {
    expect(label(FeatureValue.instrumental, LabelLanguage.sanskrit, Script.iast, short: true),
        'tṛ.');
    expect(label(FeatureValue.instrumental, LabelLanguage.sanskrit, Script.devanagari, short: true),
        'तृ.');
    expect(label(FeatureValue.vocative, LabelLanguage.sanskrit, Script.devanagari, short: true),
        'सं.');
    expect(label(FeatureValue.instrumental, LabelLanguage.english, Script.iast, short: true),
        'ins.');
    // The full name is untouched.
    expect(label(FeatureValue.instrumental, LabelLanguage.sanskrit, Script.iast),
        'tṛtīyā');
  });

  test('a value with no short name shows its full name', () {
    expect(label(FeatureValue.lat, LabelLanguage.sanskrit, Script.iast, short: true),
        'laṭ');
    expect(label(FeatureValue.lat, LabelLanguage.english, Script.iast, short: true),
        'present');
  });
}
