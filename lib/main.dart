import 'dart:io';

import 'package:app/theme/theme_provider.dart';
import 'package:app/translations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Translations;
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

import 'package:app/logic.dart';
import 'package:app/home_page.dart';

void main() async {
  // prefs is a global variable in logic.dart
  prefs = await SharedPreferences.getInstance();
  final projectsString = prefs!.getString("projects")?.trim();
  if (projectsString?.isNotEmpty ?? false) {
    final attrs = projectsString!.split(";").map((e) => e.split(","));
    final projects = (await Future.wait([
      for (final attr in attrs)
        () async {
          final dir = Directory(attr.last);
          if (await dir.exists()) {
            return Project.add(attr.first, dir);
          } else {
            return null;
          }
        }()
    ]))
        .whereType<Project>();

    /// XXX: We know that they already are in prefs
    projC.projects.addAll(projects);
  }

  final darkMode = prefs!.getBool("darkMode") ?? false;
  themeProvider.toggleTheme(darkMode);

  runApp(const MyApp());
}

ThemeProvider themeProvider = ThemeProvider();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    themeProvider.addListener(themeListener);
    super.initState();
  }

  @override
  void dispose() {
    themeProvider.removeListener(themeListener);
    super.dispose();
  }

  themeListener() {
    if (mounted) {
      setState(() {});
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final c = Get.put(projC);
    return GetMaterialApp(
      title: 'Tutor Tool',
      theme: MyThemes.lightTheme,
      darkTheme: MyThemes.darkTheme,
      themeMode: themeProvider.themeMode,
      defaultTransition: Transition.fadeIn,
      initialRoute: "/",
      routes: {"/": ((context) => const HomePage())},
      translations: Translations(),
      locale: Get.deviceLocale,
      fallbackLocale: const Locale('en', 'US'),
    );
  }
}
