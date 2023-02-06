import 'package:flutter/material.dart';
import 'Screens/home_page.dart';

void main() {
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
