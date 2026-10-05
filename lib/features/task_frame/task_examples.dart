import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../domain/domain.dart';

/// One example the user can tap: what it says and what tapping it does (fill
/// the inputs and run the request).
class TaskExample {
  const TaskExample(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;
}

/// The label of an example: [dev] is Sanskrit written in Devanagari, shown in
/// the display script; [note] is English, in parentheses.
String exampleLabel(String dev, String? note, AppSettings settings) {
  final text = SanskritText.from(dev, Script.devanagari)
      .display(settings.displayScript.script);
  return note == null ? text : '$text ($note)';
}

/// The "Try" line under a task screen's inputs (`SCREENS.md` section 4).
class ExamplesRow extends StatelessWidget {
  const ExamplesRow({super.key, required this.examples});

  final List<TaskExample> examples;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        key: const Key('examples'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Try', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final e in examples)
                ActionChip(
                  label: Text(e.label, style: const TextStyle(fontSize: 16)),
                  onPressed: e.onTap,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// An example of a screen with text inputs: the words (Devanagari) and a note.
class TextExample {
  const TextExample(this.words, [this.note]);

  /// One entry per input field.
  final List<String> words;
  final String? note;

  String get labelDev => words.join(' + ');
}

const analyseExamples = [
  TextExample(['रामः'], 'noun or verb'),
  TextExample(['गच्छति'], 'verb'),
  TextExample(['गच्छन्'], 'participle'),
  TextExample(['अहम्'], 'pronoun'),
  TextExample(['गम्यते'], 'the engines differ'),
];

const splitExamples = [
  TextExample(['रामो वनं गच्छति'], 'sentence'),
  TextExample(['रामालयः'], 'compound'),
  TextExample(['धर्मक्षेत्रे कुरुक्षेत्रे'], 'verse opening'),
];

const joinExamples = [
  TextExample(['रामः', 'आलयः'], 'two ways'),
  TextExample(['लक्ष्मीवान्', 'शुभलक्षणः'], 'four ways'),
  TextExample(['तत्', 'टीका']),
];

const dictionaryExamples = [
  TextExample(['वन']),
  TextExample(['राम']),
  TextExample(['धर्म']),
];

/// A noun example: the stem, its gender and category.
class NounExample {
  const NounExample(this.stem, this.gender, this.category, this.note);

  final String stem;
  final FeatureValue gender;
  final FeatureValue category;
  final String note;
}

const nounExamples = [
  NounExample('राम', FeatureValue.masculine, FeatureValue.plainNoun,
      'masculine'),
  NounExample('नदी', FeatureValue.feminine, FeatureValue.plainNoun, 'feminine'),
  NounExample('वन', FeatureValue.neuter, FeatureValue.plainNoun, 'neuter'),
  NounExample('अस्मद्', FeatureValue.noGender, FeatureValue.sarvanama,
      'pronoun, two forms in a cell'),
];

/// A root example for Verb forms and Kṛt forms: the dhātu key and prefix key
/// from the bundled lists, the voice, and the label in Devanagari.
class RootExample {
  const RootExample(this.labelDev, this.root,
      {this.prefix, this.prayoga = VerbPrayoga.kartari, this.note});

  final String labelDev;
  final String root;
  final String? prefix;
  final VerbPrayoga prayoga;
  final String? note;
}

const _gam = 'gam1_gamLz_BvAxiH_gawO';
const _kr = 'kq3_dukqF_wanAxiH_karaNe';
const _paTh = 'paT1_paTaz_BvAxiH_vyakwAyAM_vAci';

const verbExamples = [
  RootExample('गम्', _gam),
  RootExample('आङ् + गम्', _gam, prefix: 'Af'),
  RootExample('कृ', _kr, note: 'both padas'),
  RootExample('गम्', _gam, prayoga: VerbPrayoga.karmani, note: 'passive'),
  RootExample('गम्', _gam, prayoga: VerbPrayoga.nijanta, note: 'causative'),
];

const krtExamples = [
  RootExample('गम्', _gam),
  RootExample('कृ', _kr),
  RootExample('पठ्', _paTh),
  RootExample('प्र + गम्', _gam, prefix: 'pra'),
];
