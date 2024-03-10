import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:mobile_app/Constants/constants.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

/// ************************************************************
/// This is the SettingsPage for the Android version.
/// It provides options for the user to select the input and output encoding
/// which is used throughout the app for the conversion of text
class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saṃsādhanī Settings'),
      ),
      body: body(),
    );
  }

  Widget body() {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Column(
            children: [
              SizedBox(height: 10),
              Text(
                'Select your preferred input and',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSans',
                ),
              ),
              Text(
                ' output encoding',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              /// Input Encoding
              Container(
                padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                child: FormBuilderDropdown(
                  name: 'Input encoding: ',
                  items: Const.inputEncodingList.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Input encoding: ',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: inputEncodingStr,
                  onChanged: (value) {
                    inputEncodingStr = value!;
                  },
                ),
              ),

              /// Output Encoding
              Container(
                padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                child: FormBuilderDropdown(
                  name: 'Output encoding: ',
                  items: Const.outputEncodingList.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Output encoding: ',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: outputEncodingStr,
                  onChanged: (value) {
                    outputEncodingStr = value!;
                  },
                ),
              ),
            ],
          ),
          const Column(
            children: [
              SizedBox(height: 10),
              Text('This will be used throughout this app',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );
  }
}
