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
// import 'package:io';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;
import 'package:window_size/window_size.dart' as windowSize;

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

final isDesktop = Platform.isIOS || Platform.isLinux || Platform.isWindows;
Future<Size> getMonitorSize() async {
  return (await windowSize.getCurrentScreen())?.visibleFrame.size ??
      const Size(0, 0);
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
      Get.snackbar("couldnt_add_project".tr, "");
    });
  }

  removeProjectAt(int pos) {
    projects.removeAt(pos);
    persistProjects().then((value) => null).catchError((e) {
      Get.snackbar("couldnt_remove_project".tr, "");
    });
  }
}

final projC = Controller();

/// The regex to parse the names from student dirs
final studentDirRegex = RegExp(r"([^,]+), (.*)\((.*)\)");
final File devNull = Platform.isWindows ? File("NUL") : File("/dev/null");

const submissionAttachments = "Submission attachment(s)";
const feedbackAttachments = "Feedback Attachment(s)";

class Project {
  final String name;
  final Directory dir;
  List<Group> groups = [];
  int currGroup = -1;
  String commentsTemplate = "";

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
  File groupCommentFile(int index) =>
      groups[index].firstWhereOrNull((element) => true)?.commentsFile ??
      devNull;

  /// Sets the groups comments
  Future<void> setGroupComment(int index, String comment) async {
    await Future.wait([
      for (final student in groups[index])
        student.commentsFile.writeAsString(comment, flush: true)
    ]);
  }

  /// Get the grade of a group
  Future<num?> groupGrade(int index) async =>
      getGrade(await groupCommentFile(index).readAsString());

  /// Get the index of a group. Sugar for project.groups.indexOf
  int groupIndex(Group group) => groups.indexOf(group);

  /// Saves the project to the projectFile
  Future<void> save() async {
    await projFile.writeAsString(json.encode(toJson()));
  }

  /// Sets the current group but also saves the project simultaneously
  Future<void> setCurrGroup(int index) async {
    currGroup = index;
    await save();
  }

  /// Sorts the project
  Future<void> sort() async {
    // Put submitters first
    for (final group in groups) {
      group.sort((a, b) => a.didSubmit ? -1 : 1);
    }
    // Sort the groups by whether the group submitted then by the groups length
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

  /// Removes all empty groups
  void clean() {
    groups.removeWhere((group) => group.isEmpty);
  }

  /// Initializes the project. For this the students submission files are updated.
  Future<void> init() async {
    await Future.wait([for (final student in students) student.update()]);
  }

  /// Resets students from the project directory
  Future<void> reset() async {
    groups = [
      for (final subdir in dir.listSync())
        if (subdir is Directory)
          [Student.fromDirName(p.basename(subdir.path), project: this)]
    ];
    await sort();
    await init();
  }

  /// Sets the comments template
  Future<void> setCommentsTemplate(String template) async {
    for (int i = 0; i < groups.length; i++) {
      final group = groups[i];
      // We only apply if the group has submitted and the comment hasn't been changed
      if (didGroupSubmit(group) &&
          (await groupCommentFile(i).readAsString()) == commentsTemplate) {
        setGroupComment(i, template);
      }
    }
    commentsTemplate = template;
    await save();
  }

  /// Submits the project (grades and zipping)
  Future<void> submit(Iterable<Pair<List<Student>, num>> grades) async {
    // Enter grades
    final rows = loadCSV(await gradesFile.readAsString());
    final failedGrading = [
      for (final pair in grades)
        for (final student in pair.first) student.setGrade(rows, pair.second)
    ].where((e) => e != null);
    await gradesFile.writeAsString(storeCSV(rows), flush: true);
    if (failedGrading.isNotEmpty) {
      Get.bottomSheet(Container(
          decoration: const BoxDecoration(color: Colors.white),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Failed for: ${failedGrading.join(", ")}'),
          )));
    } else {
      // Only ZIP when entering grades worked
      final copiedDir = Directory('${dir.path} - Feedback');
      final zipPath = '${copiedDir.path}.zip';
      try {
        // Best alternative would be to add all files except for the project.json
        // But I don't know how to do that with archive.
        // Maybe ZipDirectory.createFromFiles?
        // Now we do this:
        // Copy the directory
        // then delete the project.json in that copy
        // then zip the copied directory
        // then delete that directory
        copyDir(dir, copiedDir);
        try {
          // if this fails, we don't care
          await File(p.join(copiedDir.path, "project.json")).delete();
        } catch (_) {}
        final encoder = ZipFileEncoder();
        encoder.create(zipPath);
        encoder.addDirectory(copiedDir);
        encoder.close();
        await copiedDir.delete(recursive: true);
        openDir(File(zipPath));
      } catch (e) {
        Get.snackbar("zip_failed".tr, "zip_encoder_failed".tr);
      }
    }
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
      'commentsTemplate': commentsTemplate
    };
  }

  /// Loads from file system
  Future<void> load() async {
    if (await projFile.exists()) {
      try {
        final data = jsonDecode(projFile.readAsStringSync());
        currGroup = data["lastGroup"] ?? -1;
        groups = [
          for (final group in data["groups"] ?? [])
            [
              for (final student in group)
                Student.fromJson(student, project: this)
            ]
        ];
        commentsTemplate = data["commentsTemplate"] ?? "";
        await init();
        return;
      } catch (e) {
        log("couldnt_load_project".trParams({"project": e.toString()}));
      }
    }
    await reset();
  }

  /// Add the project from the file system
  Project.add(
    this.name,
    Directory dir,
  ) : dir = dir.absolute {
    load().then((_) {});
  }

  // Project(
  //     {required this.name,
  //     required this.groups,
  //     required this.currGroup,
  //     required this.dir}) {
  //   init().then((_) {});
  // }
}

class Student {
  String lastName;
  String firstName;
  String userName;
  Project project;

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
    throw Exception; //("Could not find student in csv rows");
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
          in Directory(p.join(dir, submissionAttachments)).list())
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

  Student.fromJson(Map<String, dynamic> json, {required this.project})
      : lastName = json['lastName'],
        firstName = json['firstName'],
        userName = json['userName'];

  factory Student.fromDirName(String dirName, {required project}) {
    final match = studentDirRegex.firstMatch(dirName)!;
    return Student(match.group(1)!, match.group(2)!, match.group(3)!,
        project: project);
  }

  Student(this.lastName, this.firstName, this.userName,
      {required this.project});

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

/// Get whether a group submitted or not
bool didGroupSubmit(Group group) =>
    group.any((student) => student.submissionFiles.isNotEmpty);

double? getGrade(String text) =>
    double.tryParse(text.trim().split("\n").last.split("/").first.trim());

extension NiceNumber on num {
  String nice() {
    String s = toString();
    if (s.endsWith(".0")) {
      s = s.substring(0, s.length - 2);
    }
    return s;
  }
}
