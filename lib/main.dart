import 'dart:io';

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/settings.dart';
import 'features/home/recent_inputs.dart';

/// The app starts here: settings and recent inputs are read from the phone,
/// then the one interface (Material 3, every platform, D3) is shown. Version
/// 1's `SamMaterial` / `SamCupertino` shells stay in the repository, unused.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  final settings = await AppSettings.load();
  final recent = await RecentInputs.load();
  runApp(SamApp(settings: settings, recent: recent));
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
