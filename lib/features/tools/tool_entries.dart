import '../../domain/domain.dart';

/// The three groups of the Tools tab (`SCREENS.md` section 3).
enum ToolGroup {
  analysis('Analysis'),
  generation('Generation'),
  reference('Reference');

  const ToolGroup(this.label);

  final String label;
}

/// One row of the Tools tab and one chip on Home: a task from the catalogue,
/// or Dhātupāṭha, which is not a task (it is rebuilt as its own screen, D5).
class ToolEntry {
  final Task? task;
  final String nameEn;
  final String nameSa;
  final String description;
  final ToolGroup group;

  const ToolEntry({
    required this.task,
    required this.nameEn,
    required this.nameSa,
    required this.description,
    required this.group,
  });

  /// The engines that can answer this row today; none for Dhātupāṭha.
  Set<EngineId> get engines =>
      task == null ? const {} : (engineSupport[task] ?? const {});
}

/// Which engines answer which task today (ARCHITECTURE.md 8.4). A test checks
/// it against the engines' own `tasks` sets.
const engineSupport = <Task, Set<EngineId>>{
  Task.analyseWord: {EngineId.samsaadhanii, EngineId.heritage},
  Task.splitText: {EngineId.samsaadhanii, EngineId.heritage},
  Task.nounForms: {EngineId.samsaadhanii},
  Task.verbForms: {EngineId.samsaadhanii},
  Task.krtForms: {EngineId.samsaadhanii},
  Task.joinWords: {EngineId.samsaadhanii},
  Task.dictionary: {EngineId.samsaadhanii},
  Task.derivation: {EngineId.samsaadhanii},
};

const engineNames = {
  EngineId.samsaadhanii: 'Samsaadhanii',
  EngineId.heritage: 'Heritage',
};

ToolEntry _of(Task t, ToolGroup g) => ToolEntry(
      task: t,
      nameEn: t.nameEn,
      nameSa: t.nameSa,
      description: t.description,
      group: g,
    );

/// In display order: Analysis, Generation, Reference. Derivation is a task
/// but not a row (it opens from a noun form, `SCREENS.md` 5.4).
final List<ToolEntry> toolEntries = [
  _of(Task.analyseWord, ToolGroup.analysis),
  _of(Task.splitText, ToolGroup.analysis),
  _of(Task.nounForms, ToolGroup.generation),
  _of(Task.verbForms, ToolGroup.generation),
  _of(Task.krtForms, ToolGroup.generation),
  _of(Task.joinWords, ToolGroup.generation),
  _of(Task.dictionary, ToolGroup.reference),
  const ToolEntry(
    task: null,
    nameEn: 'Dhātupāṭhaḥ',
    nameSa: 'धातुपाठः',
    description: 'Reference list of Paninian verbal roots',
    group: ToolGroup.reference,
  ),
];

ToolEntry entryFor(Task task) =>
    toolEntries.firstWhere((e) => e.task == task);
