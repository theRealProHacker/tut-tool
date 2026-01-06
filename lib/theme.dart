import 'package:flutter/material.dart';
import 'package:app/logic.dart';
import 'package:get/get.dart';

class MyThemes {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    useMaterial3: false,
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: false,
  );
}

// More pythonic without a class but just pretty unique module members
ThemeMode themeMode = ThemeMode.light;

bool isDarkMode() {
  return themeMode == ThemeMode.dark;
}

Future<void> setupTheme() async {
  final darkMode = prefs!.getBool("darkMode") ?? false;
  if (darkMode) {
    // We are using the fact that the mode is light if not set otherwise
    toggleTheme();
  }
}

Future<void> toggleTheme() async {
  // We go to dark if we are currently in light
  final dark = !isDarkMode();
  themeMode = dark ? ThemeMode.dark : ThemeMode.light;
  await prefs!.setBool("darkMode", dark);
  Get.changeThemeMode(themeMode);
}
