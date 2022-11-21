/// Code logic

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;

import 'package:app/io.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

/// Extends Map with the get and getAny methods
extension DefaultMap<K, V> on Map<K, V> {
  V get(K key, V def) => this[key] ?? def;
  K? getAny() {
    for (final key in keys) {
      return key;
    }
    return null;
  }
}

// Needs to be initialized in main.
SharedPreferences? prefs;

/// Should be called when deleting or adding a project
Future<void> persistProjects() async {
  await prefs!.setString(
      "projects",
      [
        for (final project in projC.projects)
          [project.name, project.dir.path].join(",")
      ].join(";"));
}

class Controller extends GetxController {
  final projects = (<Project>[]).obs;

  addProject(Project project) {
    projects.add(project);
    persistProjects().then((value) => null).catchError((e) {
      Get.snackbar("Couldn't add project persistently", "");
    });
  }

  removeProjectAt(int pos) {
    projects.removeAt(pos);
    persistProjects().then((value) => null).catchError((e) {
      Get.snackbar("Couldn't remove project persistently", "");
    });
  }
}

final projC = Controller();

/// The regex to parse the names from student dirs
final studentDirRegex = RegExp(r"([^,]+), (.*)\((.*)\)");
final File devNull = Platform.isWindows ? File("NUL") : File("/dev/null");

class Project {
  String name;
  Directory dir;
  List<Group> groups = [];
  int currGroup = -1;
  Set<int> finishedGroups = {};

  /// The project.json file with the data inside
  File get projFile => File(p.join(dir.path, "project.json"));
  /// The grades.csv file
  File get gradesFile => File(p.join(dir.path, "grades.csv"));

  /// All students in the project
  List<Student> get students => [for (final group in groups) ...group];

  /// The title for the group
  String groupTitle(int index) =>
      [for (final student in groups[index]) student.displayName].join(", ");

  /// The source comment file for the group
  File groupComments(int index) =>
      groups[index].firstWhereOrNull((element) => true)?.commentsFile ??
      devNull;

  /// Get the index of a group. Sugar for project.groups.indexOf
  int groupIndex(Group group) => groups.indexOf(group);

  /// Sorts the project
  Future<void> sort() async {
    // Put submitters first
    for (final group in groups) {
      group.sort((a,b)=> a.didSubmit? -1 : 1);
    }
    groups.sort((a, b) {
      final aSubmit = a.any((s) => s.didSubmit);
      if (aSubmit != b.any((s) => s.didSubmit)) {
        return aSubmit ? -1 : 1;
      } else {
        return -a.length.compareTo(b.length);
      }
    });
    await save();
  }

  /// Cleans the project by removing all empty groups
  void clean() {
    groups.removeWhere((group) => group.isEmpty);
  }

  /// Saves the project to the projectFile
  Future<void> save() async {
    await projFile.writeAsString(json.encode(toJson()));
  }

  /// Submits the project (grades and zipping)
  Future<void> submit(Iterable<Pair<List<Student>, num>> grades) async {
    // Enter grades
    final rows = loadCSV(await gradesFile.readAsString());
    final failedGrading = [
      for (final pair in grades) 
        for (final student in pair.first)
          student.setGrade(rows, pair.second)
    ].where((e) => e != null);
    if (failedGrading.isNotEmpty) {
      Get.bottomSheet(Container(
          decoration: const BoxDecoration(
              color: Colors.white),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
                'Failed for: ${failedGrading.join(", ")}'),
          )));
    } else {
      // Only ZIP when entering grades worked
      final resultPath = '${dir.path}.zip';
      try {
        final encoder = ZipFileEncoder();
        encoder.open(resultPath);
        for (final student in students) {
          await encoder.addDirectory(Directory(student.dir));
        }
        await encoder.addFile(gradesFile);
        encoder.close();
        final resultFile = File(resultPath);
        // Hacky way to actually close the zip-file
        await (await resultFile.open()).close();
        openDir(resultFile);
      } catch (e) {
        Get.snackbar("Failed to zip", "Not all ");
      }
    }
  }

  /// Initializes the project
  void init() {
    for (final student in students) {
      student.project = this;
    }
    func() async {
      await Future.wait([for (final student in students) student.update()]);
    }

    func().then(((value) => null));
    Timer.periodic(const Duration(seconds: 5), (timer) => func());
  }

  /// Encode a project as JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lastGroup': currGroup,
      'groups': [
        for (final group in groups)
          [for (final student in group) student.toJson()]
      ],
      'finishedGroups': List.of(finishedGroups),
    };
  }

  /// Loads from file system
  void load() {
    dir = dir.absolute;
    if (projFile.existsSync()) {
      try {
        final data = jsonDecode(projFile.readAsStringSync());
        currGroup = data["lastGroup"];
        groups = [
          for (final group in data["groups"])
            [for (final student in group) Student.fromJson(student)]
        ];
        finishedGroups = {
          for (final groupIndex in data["finishedGroups"]) groupIndex as int
        };
        return;
      } catch (e) {
        log("Couldn't load project ($e)");
      }
    }
    // Initialize from directory
    groups = [
      for (final subdir in dir.listSync())
        if (subdir is Directory) [Student.fromDirName(p.basename(subdir.path))]
    ];
  }

  /// Add the project from the file system
  Project.add(
    this.name,
    this.dir,
  ) {
    load();
    init();
  }

  Project(
      {required this.name,
      required this.groups,
      required this.currGroup,
      required this.dir}) {
    init();
  }
}

class Student {
  late String lastName;
  late String firstName;
  late String userName;
  late Project project;

  // These get updated regularly
  /// The students submission files
  List<File> submissionFiles = [];

  /// The students feedback files
  List<File> feedbackFiles = [];

  /// The students directory
  String get dir =>
      p.join(project.dir.path, '$lastName, $firstName($userName)');

  /// The students comments file
  File get commentsFile => File(p.join(dir, "comments.txt"));

  /// The name that the program should display the student as
  String get displayName => '${firstName.split(" ")[0]} $lastName';

  List<dynamic> getRow(List<List<dynamic>> rows) {
    for (final row in rows) {
      if (row.first == userName) {
        return row;
      }
    }
    throw Exception("Could not find student in rows");
  }

  Student? setGrade(List<List<dynamic>> rows, num grade) {
    try {
      getRow(rows)[4] = grade;
      return null;
    } catch (e) {
      log(e.toString());
      return this;
    }
  }

  bool get didSubmit => submissionFiles.isNotEmpty;

  Future<List<File>> getSubmissionFiles() async {
    // TODO: unpack zip files
    return [
      await for (final file
          in Directory(p.join(dir, "Submission attachment(s)")).list())
        if (file is File) file
    ];
  }

  Future<String> getSubmissionText() async =>
      (await Future.wait([for (final file in submissionFiles) file2Text(file)]))
          .join(" ");

  Future<List<File>> getFeedbackFiles() async {
    return [
      await for (final file
          in Directory(p.join(dir, "Feedback attachment(s)")).list())
        if (file is File) file
    ];
  }

  Future<void> update() async {
    // Update our state with IO-state
    submissionFiles = await getSubmissionFiles();
    // feedbackFiles = await getFeedbackFiles();
  }

  Map<String, dynamic> toJson() => {
        "lastName": lastName,
        "firstName": firstName,
        "userName": userName,
      };

  @override
  bool operator ==(Object other) {
    if (other is! Student) return false;
    return userName == other.userName;
  }

  @override
  int get hashCode => userName.hashCode;

  Student.fromJson(Map<String, dynamic> json)
      : lastName = json['lastName'],
        firstName = json['firstName'],
        userName = json['userName'];

  Student.fromDirName(String dirName) {
    final match = studentDirRegex.firstMatch(dirName)!;
    lastName = match.group(1)!;
    firstName = match.group(2)!;
    userName = match.group(3)!;
  }

  Student(this.lastName, this.firstName, this.userName);

  @override
  String toString() {
    return displayName;
  }
}

typedef Group = List<Student>;

/// Automatically assign groups to the project
autoGroups(Project project) async {
  // Try to find a similar project and copy its groups
  final studentSet = Set.of(project.students);
  Project? bestProject;
  int bestMatch = (studentSet.length * 0.9).floor();
  for (final projectCandidate in projC.projects) {
    // Skip this project
    if (project == projectCandidate) continue;
    final intersectingStudents =
        studentSet.intersection(Set.of(projectCandidate.students));
    if (intersectingStudents.length >= bestMatch) {
      bestProject = projectCandidate;
      bestMatch = intersectingStudents.length;
    }
  }
  // A self referencing student map for getting students from this project.
  final studentMap = {for (final k in studentSet) k: k};
  if (bestProject != null) {
    final groups = <Group>[];
    for (final group in bestProject.groups) {
      final Group newGroup = [];
      for (final oldStudent in group) {
        final student = studentMap[oldStudent];
        if (student != null) {
          studentMap.remove(student);
          newGroup.add(student);
        }
      }
      groups.add(newGroup);
    }
    groups.addAll(studentMap.keys.map((e) => [e]));
    project.groups = groups;
    return;
  }
  // There is no similar project. Guess from the submissions.

  final students = project.students;

  /// Student that have submitted something
  final studentsWithSubmissionFiles = {
    for (final student in project.students)
      if (student.submissionFiles.isNotEmpty) student
  };

  /// Students with their submission texts
  final studentsWithSubmissions = Map.fromIterables(
      studentsWithSubmissionFiles,
      await Future.wait(
          studentsWithSubmissionFiles.map((e) => e.getSubmissionText())));

  /// The pool of students that are assigned to the other students that submitted something.
  final Set<Student> studentPool =
      Set.of(students).difference(studentsWithSubmissionFiles);

  /// A names to students mapping
  final Map<String, Set<Student>> names = {};
  for (final student in students) {
    for (final totalName in [student.lastName, student.firstName]) {
      final name = totalName.split(RegExp(r"\s+")).first.trim();
      names.putIfAbsent(name, () => {});
      names[name]!.add(student);
    }
  }

  /// The resulting groups
  final List<Group> groups = [];
  for (final entry in studentsWithSubmissions.entries) {
    final currentStudent = entry.key;
    final Map<Student, int> bestScores = {};
    final Map<Student, int> currentScores = {};
    String text = entry.value
        .replaceAll(RegExp(r"[^\w|\s]", unicode: true), "")
        .replaceAllMapped(RegExp(r"(?<!\s)[A-Z]", unicode: true),
            (match) => " ${match.group(0)!}");
    for (var word in text.split(RegExp(r"\s+"))) {
      // Make sure word is alphabetical
      final matchingStudents = names.get(word, {});
      for (final student in matchingStudents) {
        final score = currentScores.get(student, 0) + 1;
        currentScores[student] = score;
        bestScores[student] = max(bestScores.get(student, 0), score);
      }
    }
    bestScores.removeWhere(((key, value) => !studentPool.contains(key)));
    final maxScore = bestScores.values.fold(0, max);
    bestScores.removeWhere((key, value) => value < maxScore);
    // final bestStudent = studentScore.getAny() ?? currentStudent;
    groups.add(Group.of({currentStudent, ...bestScores.keys}));
    studentPool.removeAll(bestScores.keys);
  }
  groups.addAll([
    for (final leftoverStudent in studentPool) [leftoverStudent]
  ]);
  project.groups = groups;
}

// Draft for guessing the maximum available points
// Pair<int,int?> getGrades {

// }

class Pair<T1, T2> {
  final T1 first;
  final T2 second;
  Pair(this.first, this.second);
}

Iterable<Pair<T1, T2>> zip<T1, T2>(
    Iterable<T1> iter1, Iterable<T2> iter2) sync* {
  final iter2iter = iter2.iterator;
  for (final t1 in iter1) {
    if (!iter2iter.moveNext()) break;
    yield Pair(t1, iter2iter.current);
  }
}

// (number)/
final gradeRegex = RegExp(r"(\d+(?:\.\d*)?)\/", unicode: true);

num? getGrade(String text) {
  text = text.trim();
  return double.tryParse(text.split("\n").last.split("/").first.trim());
}

String niceNum(num d) {
  String s = d.toString();
  if (s.endsWith(".0")) {
    s = s.substring(0, s.length - 2);
  }
  return s;
}
