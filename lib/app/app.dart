import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_theme.dart';
import '../domain/domain.dart';
import '../engines/heritage/heritage_engine.dart';
import '../engines/samsaadhanii/samsaadhanii_engine.dart';
import '../features/task_frame/engine_set.dart';
import '../features/home/dhatu_index.dart';
import '../features/home/recent_inputs.dart';
import '../shared/data/word_lists.dart';
import 'app_info.dart';
import 'app_shell.dart';
import 'settings.dart';

/// The app: one Material 3 interface on every platform (D3).
class SamApp extends StatelessWidget {
  const SamApp({
    super.key,
    required this.settings,
    required this.recent,
    this.engines,
    this.dhatuIndex,
    this.dhatus,
    this.prefixes,
  });

  final AppSettings settings;
  final RecentInputs recent;

  /// The engines screens use; the two real ones unless a test passes others.
  final EngineSet? engines;

  /// The bundled lists screens read; the ones read from the assets unless a
  /// test passes others.
  final DhatuIndex? dhatuIndex;
  final DhatuList? dhatus;
  final PrefixList? prefixes;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: recent),
        Provider<EngineSet>(
          create: (_) =>
              engines ??
              EngineSet({
                EngineId.samsaadhanii: SamsaadhaniiEngine(),
                EngineId.heritage: HeritageEngine(),
              }),
        ),
        dhatuIndex != null
            ? ChangeNotifierProvider.value(value: dhatuIndex!)
            : ChangeNotifierProvider(create: (_) => DhatuIndex()..load()),
        // The root and prefix pickers and the Verb forms screen. Read from
        // the assets at start, so the pickers are ready when a screen opens.
        dhatus != null
            ? ChangeNotifierProvider<DhatuList>.value(value: dhatus!)
            : ChangeNotifierProvider(
                lazy: false, create: (_) => DhatuList()..load()),
        prefixes != null
            ? ChangeNotifierProvider<PrefixList>.value(value: prefixes!)
            : ChangeNotifierProvider(
                lazy: false, create: (_) => PrefixList()..load()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: appDisplayName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AppShell(),
      ),
    );
  }
}
