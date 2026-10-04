import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/settings.dart';
import 'features/home/recent_inputs.dart';

/// The app starts here: settings and recent inputs are read from the phone,
/// then the one interface (Material 3, every platform, D3) is shown.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  final recent = await RecentInputs.load();
  runApp(SamApp(settings: settings, recent: recent));
}
