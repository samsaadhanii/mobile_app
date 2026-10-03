import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Data provider class to provide data to the app using ChangeNotifier

class DataProvider extends ChangeNotifier {
  bool verbDataLoaded = false;
  bool prefixDataLoaded = false;
  List<Map<String, dynamic>> verbData = [];
  List<Map<String, dynamic>> prefixData = [];

  DataProvider() {
    rootBundle.loadString('assets/verblist.json').then((value) {
      List<dynamic> data = json.decode(value);
      print('verb data: ${data.length}');
      for (var element in data) {
        Map<String, dynamic> tmp = element;
        verbData.add(tmp);
      }
      verbDataLoaded = true;
      notifyListeners();
    });

    /// Load prefix list (with roman forms) from assets
    rootBundle.loadString('assets/prefix_list.json').then((value) {
      List<dynamic> data = json.decode(value);
      print('verb data: ${data.length}');
      prefixData.add({"wx": "-", "dev": "-", "rom": "-"});
      for (var element in data) {
        Map<String, dynamic> tmp = element;
        prefixData.add(tmp);
      }
      prefixDataLoaded = true;
      notifyListeners();
    });
  }
  // int _count = 0;
  //
  // // Getter to access the count value
  // int get count => _count;
  //
  // // Function to increment the count
  // void increment() {
  //   _count++;
  //   notifyListeners(); // Notify listeners (widgets) that the data has changed
  // }
  //
  // // Function to decrement the count
  // void decrement() {
  //   _count--;
  //   notifyListeners(); // Notify listeners (widgets) that the data has changed
  // }
}
