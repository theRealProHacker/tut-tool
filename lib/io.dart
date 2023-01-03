// ignore_for_file: empty_catches

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:app/translations.dart';
import 'package:app/logic.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart' as pdf;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_highlight/theme_map.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

// Ein bisschen weird: jede Sprache hat ihre eigene Datei
import 'package:highlight/languages/haskell.dart' show haskell;
import 'package:highlight/languages/avrasm.dart' show avrasm;
import 'package:highlight/languages/python.dart' show python;
import 'package:highlight/languages/plaintext.dart' show plaintext;

// for old flutter_highlighter
// const langMap = {
//   ".hs": "Haskell",
//   ".txt": "Plaintext",
//   ".s": "avrasm",
//   ".asm": "avrasm",
//   ".py": "Python"
// };
final langMap = {
  ".hs": haskell,
  ".txt": plaintext,
  ".s": avrasm,
  ".asm": avrasm,
  ".py": python,
};

/// The Comments input text field
class CommentsTextField extends StatelessWidget {
  const CommentsTextField({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
          labelText: "comments".tr,
          alignLabelWithHint: true,
          border: const OutlineInputBorder()),
      controller: controller,
      maxLines: 20,
      minLines: 5,
      cursorRadius: const Radius.circular(5),
    );
  }
}

/// A Widget to display a file
class SubmissionFileShower extends StatelessWidget {
  final File file;
  const SubmissionFileShower(this.file, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ext = p.extension(file.path);
    if (ext == ".pdf") {
      return Text("pdf_warning".tr);
    } else if (langMap.containsKey(ext)) {
      return FutureBuilder(
          future: file.readAsString(),
          builder: ((context, snapshot) => snapshot.hasData
              ? CodeEditor(snapshot.data!, file)
              : Text("loading".tr)));
    } else {
      return Text("unknown_file_format".tr);
    }
  }
}

// HighlightView(
//   snapshot.data!,
//   language: langMap[ext],
//   theme: context.isDarkMode
//       ? themeMap["tomorrow-night"]!
//       : themeMap["github"]!,
//   padding: const EdgeInsets.all(12),
//   textStyle: const TextStyle(
//       fontFamily:
//           'MonoLisa,SFMono-Regular,Consolas,Liberation Mono,Menlo,monospace'),
// )

class CodeEditor extends StatelessWidget {
  final controller = CodeController();
  File writeFile;
  CodeEditor(contents, this.writeFile, {Key? key}) : super(key: key) {
    controller.text = contents;
    controller.language = langMap[p.extension(writeFile.path)]!;
    controller.addListener(() async {
      writeFile.writeAsString(controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = CodeTheme(
      data: CodeThemeData(
          styles: context.isDarkMode
              ? themeMap["tomorrow-night"]!
              : themeMap["github"]!),
      child: CodeField(
        controller: controller,
        textStyle: const TextStyle(
            fontFamily:
                'MonoLisa,SFMono-Regular,Consolas,Liberation Mono,Menlo,monospace'),
      ),
    );
    // a hack to enable automatic coloring (probably an issue in the CodeField)
    final oldWriteFile = writeFile;
    writeFile = devNull;
    controller.text += " ";
    controller.backspace();
    writeFile = oldWriteFile;
    return theme;
  }
}

/// A Directory Input
/// It uses a read-only TextField but opens a file picker on tap
class DirInput extends StatelessWidget {
  DirInput({Key? key}) : super(key: key);

  final controller = TextEditingController();

  /// Must only be read when validated!
  Directory get value => Directory(controller.text).absolute;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(hintText: "choose_dir".tr),
      validator: (text) => text!.isEmpty
          ? "choose_dir".tr
          : (value.existsSync() ? null : "directory_doesnt_exist".tr),
      onTap: () async {
        final selectedDir = await FilePicker.platform
            .getDirectoryPath(dialogTitle: "select_dir".tr);
        if (selectedDir != null) {
          controller.text = selectedDir;
        }
      },
    );
  }
}

void openFile(File file) {
  try {
    if (Platform.isWindows) {
      Process.run("explorer", [file.path]);
    } else if (Platform.isLinux) {
      Process.run("xdg-open", [file.path]);
    } else if (Platform.isMacOS) {
      Process.run("open", [file.path]);
    } else {
      throw Exception();
    }
  } catch (e) {
    Get.snackbar("cant_open_file".tr, notSupportedOnPlatform());
  }
}

void openDir(File file) {
  try {
    if (Platform.isWindows) {
      Process.run("explorer", [p.dirname(file.path)]);
    } else if (Platform.isLinux) {
      Process.run("xdg-open", [p.dirname(file.path)]);
    } else if (Platform.isMacOS) {
      Process.run("open", ["-R", file.path]);
    } else {
      throw Exception();
    }
  } catch (e) {
    Get.snackbar("cant_open_dir".tr, notSupportedOnPlatform());
  }
}

void consoleDir(File file) {
  try {
    if (Platform.isWindows) {
      Process.run("start", ["cmd"],
          runInShell: true, workingDirectory: p.dirname(file.path));
    } else if (Platform.isLinux) {
      Process.run("x-terminal-emulator", [],
          workingDirectory: p.dirname(file.path));
    } else if (Platform.isMacOS) {
      Process.run("open", ["-n", "-a", "Terminal"],
          workingDirectory: p.dirname(file.path));
    } else {
      throw Exception();
    }
  } catch (e) {
    Get.snackbar("cant_open_terminal".tr, notSupportedOnPlatform());
  }
}

/// Runs/Starts a file
void runFile(File file) {
  final path = file.path;
  final ext = p.extension(path);
  try {
    if (ext == ".hs") {
      if (Platform.isWindows) {
        Process.run("start", ["ghci", p.basename(path)],
            runInShell: true, workingDirectory: p.dirname(path));
      } else if (Platform.isLinux) {
        Process.start("x-terminal-emulator", ["-e", "ghci", p.basename(path)],
            workingDirectory: p.dirname(file.path));
      } else if (Platform.isMacOS) {
        Process.run("open", ["-a", "ghci", path]);
      } else {
        throw Exception();
      }
    } else {
      openFile(file);
    }
  } catch (e) {
    Get.snackbar("cant_run_file".tr, notSupportedOnPlatform());
  }
}

// https://gist.github.com/thosakwe/681056e86673e73c4710cfbdfd2523a8
// Future<void> copyDirectory(Directory source, Directory destination) async {
//   await for (var entity in source.list(recursive: false)) {
//     if (entity is Directory) {
//       var newDirectory =
//           Directory(p.join(destination.absolute.path, p.basename(entity.path)));
//       await newDirectory.create();
//       await copyDirectory(entity.absolute, newDirectory);
//     } else if (entity is File) {
//       await entity.copy(p.join(destination.path, p.basename(entity.path)));
//     }
//   }
// }

void copyDir(Directory source, Directory destination) {
  if (Platform.isWindows) {
    Process.run(
        "Xcopy", ["/E", "/I", source.absolute.path, destination.absolute.path]);
  } else if (Platform.isLinux || Platform.isMacOS) {
    Process.run("cp", ["-r", source.absolute.path, destination.absolute.path]);
  } else {
    Get.snackbar("cant_copy_dir".tr, notSupportedOnPlatform());
  }
}

/// Converts file2Text
Future<String> file2Text(File file) async {
  // TODO: unpack zip files
  final ext = p.extension(file.path);
  if (langMap.containsKey(ext)) {
    return await file.readAsString();
  } else if (ext == ".pdf") {
    try {
      final document = pdf.PdfDocument(inputBytes: await file.readAsBytes());
      String text = pdf.PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      log("cant_extract_pdf".trParams({"path": file.path}));
    }
  }
  return "";
}

dynamic parseDynamic(String word) {
  word = word.replaceAll('"', "").trim();
  return int.tryParse(word) ?? double.tryParse(word) ?? word;
}

List<List<dynamic>> loadCSV(String text) => [
      for (final line in text.split("\n"))
        [for (final field in line.trim().split(",")) parseDynamic(field)]
    ];

String storeCSV(List<List<dynamic>> table) => [
      for (final line in table) [for (final field in line) '"$field"'].join(",")
    ].join("\n");
