import 'package:flutter/material.dart';
import 'package:app/logic.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  get themeMode => _themeMode;

  Future<void> toggleTheme(bool dark) async {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    await prefs!.setBool("darkMode", dark);
  }
}

class MyThemes {
  static final ThemeData lightTheme =
      ThemeData(brightness: Brightness.light, primarySwatch: Colors.blue);

  static final ThemeData darkTheme = ThemeData(brightness: Brightness.dark);
}
