import 'dart:io';

import 'package:app/theme.dart';
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
  // Loading projects
  final projectsString = prefs!.getString("projects")?.trim();
  if (projectsString?.isNotEmpty ?? false) {
    final attrs = projectsString!.split(";").map((e) => e.split(","));
    final projects = (await Future.wait([
      for (final attr in attrs)
        () async {
          final dir = Directory(attr.last);
          return await dir.exists() ? Project.add(attr.first, dir) : null;
        }()
    ]))
        .whereType<Project>();

    /// XXX: We know that they already are in prefs
    projC.projects.addAll(projects);
  }

  await setupTheme();

  runApp(GetMaterialApp(
    title: 'Tutor Tool',
    theme: MyThemes.lightTheme,
    darkTheme: MyThemes.darkTheme,
    themeMode: themeMode,
    defaultTransition: Transition.fadeIn,
    initialRoute: "/",
    routes: {"/": ((context) => const HomePage())},
    translations: Translations(),
    locale: Get.deviceLocale,
    fallbackLocale: const Locale('en', 'US'),
  ));
}
