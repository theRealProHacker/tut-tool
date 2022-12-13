import 'package:flutter/material.dart';
import 'package:app/main.dart';
import 'package:get/get.dart';

/// Settings Page that allows the user to choose preferences
class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

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

class ThemeChangeSwitch extends StatefulWidget {
  const ThemeChangeSwitch({super.key});

  @override
  State<StatefulWidget> createState() => _ThemeChangeSwitchState();
}

class _ThemeChangeSwitchState extends State<ThemeChangeSwitch> {
  bool dark = true;

  @override
  void initState() {
    dark = themeProvider.isDarkMode;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Switch(
        value: dark,
        onChanged: (bool value) {
          themeProvider.toggleTheme(value);
          setState(() {
            dark = value;
          });
        });
  }
}
