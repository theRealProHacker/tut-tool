import 'package:flutter/material.dart';
import 'package:app/main.dart';

/// Settings Page that allows the user to choose preferences
class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Settings")),
        body: ListView(
          padding: const EdgeInsets.all(8.0),
          children: <Widget>[
            Row(children: [
              ThemeChangeSwitch(),
              const Text("Enable Dark Mode"),
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
