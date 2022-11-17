import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

import 'package:app/logic.dart';
import 'package:app/home_page.dart';

void main() async {
  // prefs is a global variable in logic.dart
  prefs = await SharedPreferences.getInstance();
  log(prefs!.getString("projects")!);
  final projects = prefs!.getString("projects")?.split(";") ?? [];
  for (final project in projects) {
    if (project.isEmpty) continue;
    final attr = project.split(",");
    final dir = Directory(attr.last).absolute;
    projC.projects.add(Project.add(attr.first, dir));
  }
  persistProjects(); // Removes invalid projects automatically
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final c = Get.put(projC);
    return GetMaterialApp(
      title: 'Tutor Tool',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      defaultTransition: Transition.fadeIn,
      initialRoute: "/",
      routes: {"/": ((context) => const HomePage())},
    );
  }
}
