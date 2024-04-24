import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../web_api.dart';

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

    /// Load prefix list from assets and convert wx to roman using webAPI
    rootBundle.loadString('assets/prefix_list.json').then((value) {
      List<dynamic> data = json.decode(value);
      print('verb data: ${data.length}');
      List<String> source = [];
      prefixData.add({"wx": "-", "dev": "-", "rom": "-"});
      for (var element in data) {
        Map<String, dynamic> tmp = element;
        source.add(tmp['wx']);
        // WebAPI.transLiterateWord(input: tmp["wx"], src: 'wx', tar: 'IAST')
        //     .then((value) => tmp["rom"] = value);
        prefixData.add(tmp);
      }
      WebAPI.transLiterateData(body: source).then((value) {
        if (value.isNotEmpty) {
          for (int i = 1; i < prefixData.length; i++) {
            prefixData[i]['rom'] = value[i - 1];
          }
        }
        prefixDataLoaded = true;
        notifyListeners();
      });
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
