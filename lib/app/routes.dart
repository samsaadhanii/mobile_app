import 'package:flutter/material.dart';

import '../domain/domain.dart';
import '../features/tools/coming_soon_page.dart';
import '../features/tools/screens/krt_generator_screen.dart';
import '../features/tools/screens/morph_analyser_screen.dart';
import '../features/tools/screens/noun_generator_screen.dart';
import '../features/tools/screens/sandhi_analyser_screen.dart';
import '../features/tools/screens/sandhi_joining_screen.dart';
import '../features/tools/screens/verb_generator_screen.dart';
import '../features/tools/tool_entries.dart';

/// Opens the screen for [entry]. Until a task has its new screen this is the
/// existing v2 screen, which does not take an input yet, so [input] is not
/// passed on; Dictionary and Dhātupāṭha have no screen and open a
/// placeholder (D5 forbids the web page).
void openTool(BuildContext context, ToolEntry entry, String input) {
  final Widget page = switch (entry.task) {
    Task.analyseWord => const MorphAnalyserScreen(),
    Task.splitText => const SandhiAnalyserScreen(),
    Task.nounForms => const NounGeneratorScreen(),
    Task.verbForms => const VerbGeneratorScreen(),
    Task.krtForms => const KrtGeneratorScreen(),
    Task.joinWords => const SandhiJoiningScreen(),
    _ => ComingSoonPage(title: entry.nameEn),
  };
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}
