import 'package:flutter/material.dart';

import '../domain/domain.dart';
import '../features/tools/coming_soon_page.dart';
import '../features/tools/screens/krt_generator_screen.dart';
import '../features/analyse_word/analyse_word_screen.dart';
import '../features/noun_forms/noun_forms_screen.dart';
import '../features/split/split_screen.dart';
import '../features/tools/screens/sandhi_joining_screen.dart';
import '../features/verb_forms/verb_forms_screen.dart';
import '../features/tools/tool_entries.dart';

/// Opens the screen for [entry], with [input] filled in for the four new task
/// screens (Analyse a word, Split and analyse, Noun forms, Verb forms); Noun forms also
/// takes the [gender] and Verb forms the [prefix] when the caller has one. The other tasks still open
/// their existing v2 screen, empty, until their replacements come; Dictionary
/// and Dhātupāṭha have no screen and open a placeholder (D5 forbids the web
/// page).
void openTool(BuildContext context, ToolEntry entry, String input,
    {FeatureValue? gender, String? prefix}) {
  final Widget page = switch (entry.task) {
    Task.analyseWord => AnalyseWordScreen(
        initialInput: input,
        onOpenTool: (e, i, {gender, prefix}) => openTool(context, e, i, gender: gender, prefix: prefix),
      ),
    Task.splitText => SplitScreen(
        initialInput: input,
        onOpenTool: (e, i, {gender, prefix}) => openTool(context, e, i, gender: gender, prefix: prefix),
      ),
    Task.nounForms => NounFormsScreen(
        initialInput: input,
        initialGender: gender,
        onOpenTool: (e, i, {gender, prefix}) => openTool(context, e, i, gender: gender, prefix: prefix),
      ),
    Task.verbForms => VerbFormsScreen(
        initialInput: input,
        initialPrefix: prefix,
        onOpenTool: (e, i, {gender, prefix}) => openTool(context, e, i, gender: gender, prefix: prefix),
      ),
    Task.krtForms => const KrtGeneratorScreen(),
    Task.joinWords => const SandhiJoiningScreen(),
    _ => ComingSoonPage(title: entry.nameEn),
  };
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}
