import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_theme.dart';
import '../domain/domain.dart';
import '../engines/heritage/heritage_engine.dart';
import '../engines/samsaadhanii/samsaadhanii_engine.dart';
import '../features/task_frame/engine_set.dart';
import '../features/home/dhatu_index.dart';
import '../features/home/recent_inputs.dart';
import '../model/data_provider.dart';
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
  });

  final AppSettings settings;
  final RecentInputs recent;

  /// The engines screens use; the two real ones unless a test passes others.
  final EngineSet? engines;

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
        ChangeNotifierProvider(create: (_) => DhatuIndex()..load()),
        // Still read by the version 2 tool screens for the dhātu and prefix
        // lists.
        ChangeNotifierProvider(create: (_) => DataProvider()),
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
