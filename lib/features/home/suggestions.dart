import '../../domain/domain.dart';
import 'dhatu_index.dart';

/// One tappable row under the input box.
class Suggestion {
  final Task task;

  const Suggestion(this.task);

  @override
  bool operator ==(Object other) => other is Suggestion && other.task == task;

  @override
  int get hashCode => task.hashCode;

  @override
  String toString() => 'Suggestion(${task.name})';
}

/// The rows to offer for an input (`SCREENS.md` section 2), in order.
///
/// [words] are the input's words, already in WX. [analysisFoundNothing] is
/// for a single word that an analysis found nothing for; nothing sets it yet,
/// because no engine is called from Home (U9 will).
List<Suggestion> suggestionsFor(
  List<String> words, {
  required DhatuIndex dhatus,
  bool analysisFoundNothing = false,
}) {
  if (words.isEmpty) return const [];

  final tasks = <Task>[];
  if (words.length >= 2) {
    tasks.addAll([Task.splitText, Task.analyseWord]);
    if (words.length == 2) tasks.add(Task.joinWords);
  } else {
    if (analysisFoundNothing) tasks.addAll([Task.splitText, Task.analyseWord]);
    if (!tasks.contains(Task.analyseWord)) tasks.add(Task.analyseWord);
    tasks.addAll([Task.dictionary, Task.nounForms]);
    if (dhatus.contains(words.single)) {
      tasks.addAll([Task.verbForms, Task.krtForms]);
    }
  }
  return [for (final t in tasks) Suggestion(t)];
}
