import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/engines/heritage/heritage_engine.dart';
import 'package:mobile_app/engines/samsaadhanii/samsaadhanii_engine.dart';
import 'package:mobile_app/features/tools/tool_entries.dart';

void main() {
  test('three groups in order: Analysis, Generation, Reference', () {
    expect(ToolGroup.values.map((g) => g.label),
        ['Analysis', 'Generation', 'Reference']);
    expect(toolEntries.map((e) => e.group).toSet().length, 3);
    // Entries are listed group by group.
    var last = 0;
    for (final e in toolEntries) {
      expect(e.group.index >= last, isTrue);
      last = e.group.index;
    }
  });

  test('the rows, from the task catalogue plus Dhātupāṭha', () {
    expect(toolEntries.map((e) => e.nameEn), [
      Task.analyseWord.nameEn,
      Task.splitText.nameEn,
      Task.nounForms.nameEn,
      Task.verbForms.nameEn,
      Task.krtForms.nameEn,
      Task.joinWords.nameEn,
      Task.dictionary.nameEn,
      'Dhātupāṭhaḥ',
    ]);
    expect(toolEntries.last.task, isNull);
    expect(toolEntries.last.engines, isEmpty);
    // Derivation is a task but not a row.
    expect(toolEntries.any((e) => e.task == Task.derivation), isFalse);
  });

  test('engineSupport agrees with what the engines say they can do', () {
    final sam = SamsaadhaniiEngine().tasks;
    final her = HeritageEngine().tasks;
    for (final task in Task.values) {
      final listed = engineSupport[task]!;
      // Everything an engine offers is listed ...
      if (sam.contains(task)) expect(listed, contains(EngineId.samsaadhanii));
      // ... and Heritage is listed exactly where its engine offers the task.
      expect(listed.contains(EngineId.heritage), her.contains(task),
          reason: task.name);
    }
  });

  test('entryFor finds a row by task', () {
    expect(entryFor(Task.dictionary).group, ToolGroup.reference);
  });
}
