import 'package:app/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Settings Page that allows the user to choose preferences
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("settings".tr)),
        body: ListView(
          padding: const EdgeInsets.all(8.0),
          children: <Widget>[
            Row(children: [
              const ThemeChangeSwitch(),
              Text("enable_dark_mode".tr),
            ]),
          ],
        ));
  }
}

/// Really just a switch how it should behave anyway.
class ThemeChangeSwitch extends StatefulWidget {
  const ThemeChangeSwitch({super.key});

  @override
  State<ThemeChangeSwitch> createState() => _ThemeChangeSwitchState();
}

class _ThemeChangeSwitchState extends State<ThemeChangeSwitch> {
  @override
  Widget build(BuildContext context) {
    return Switch(
        value: isDarkMode(),
        onChanged: (bool _) {
          toggleTheme();
          setState(() {});
        });
  }
}
