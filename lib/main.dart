import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_app/theme_data.dart';

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const Samsaadhanii());
}

class Samsaadhanii extends StatelessWidget {
  const Samsaadhanii({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    print('themeBlue: ${ThemeBlueWhite.themeBlue}');
    return ThemeBlueWhite.theApp('Saṃsādhanī');
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
