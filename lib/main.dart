import 'dart:io';
import 'package:flutter/material.dart';
import 'Screens/home_page.dart';

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const Samsaadhanii());
}

class Samsaadhanii extends StatelessWidget {
  const Samsaadhanii({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(title: 'Samsaadhanii'),
    );
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
