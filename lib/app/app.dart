import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_theme.dart';
import '../features/home/dhatu_index.dart';
import '../features/home/recent_inputs.dart';
import '../model/data_provider.dart';
import 'app_info.dart';
import 'app_shell.dart';
import 'settings.dart';

/// The app: one Material 3 interface on every platform (D3).
class SamApp extends StatelessWidget {
  const SamApp({super.key, required this.settings, required this.recent});

  final AppSettings settings;
  final RecentInputs recent;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: recent),
        ChangeNotifierProvider(create: (_) => DhatuIndex()..load()),
        // Still read by the version 2 tool screens for the dhātu and prefix
        // lists.
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: appDisplayName,
        theme: AppTheme.lightTheme,
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4DB6AC),
            brightness: Brightness.dark,
          ),
        ),
        themeMode: ThemeMode.system,
        home: const AppShell(),
      ),
    );
  }
}
