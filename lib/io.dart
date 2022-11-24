// ignore_for_file: empty_catches

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:syncfusion_flutter_pdf/pdf.dart' as pdf;
import 'package:flutter_highlighter/flutter_highlighter.dart';
import 'package:flutter_highlighter/theme_map.dart';
import 'package:file_picker/file_picker.dart';

const textFiles = [".hs", ".txt", ".s", ".asm", ".py"];
const langMap = {
  ".hs": "Haskell",
  ".txt": "Plaintext",
  ".s": "avrasm",
  ".asm": "avrasm",
  ".py": "Python"
};

/// THe Comments input text field
class CommentsTextField extends StatelessWidget {
  const CommentsTextField({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(
          labelText: "Comments",
          alignLabelWithHint: true,
          border: OutlineInputBorder()),
      controller: controller,
      maxLines: 20,
      minLines: 5,
      cursorRadius: const Radius.circular(5),
    );
  }
}

/// A Widget to display a file
class FileShower extends StatelessWidget {
  final File file;
  const FileShower(this.file, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ext = p.extension(file.path);
    if (ext == ".pdf") {
      return const Text("PDF is in the working");
      return Container(
        constraints: const BoxConstraints(maxHeight: 1500),
        child: pdfx.PdfView(
          controller: pdfx.PdfController(
              document: pdfx.PdfDocument.openFile(file.path)),
        ),
      );
    } else if (textFiles.contains(ext)) {
      return FutureBuilder(
          future: file.readAsString(),
          builder: ((context, snapshot) => snapshot.hasData
              ? HighlightView(
                  snapshot.data!,
                  language: langMap[ext],
                  theme: context.isDarkMode
                      ? themeMap["tomorrow-night"]!
                      : themeMap["github"]!,
                  padding: const EdgeInsets.all(12),
                  textStyle: const TextStyle(
                      fontFamily:
                          'MonoLisa,SFMono-Regular,Consolas,Liberation Mono,Menlo,monospace'),
                )
              : const Text("Loading...")));
    } else {
      return const Text("Unknown File Format");
    }
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
      decoration: const InputDecoration(hintText: "Choose Directory"),
      validator: (text) => text!.isEmpty
          ? "Choose a directory"
          : (value.existsSync() ? null : "Directory doesn't exist"),
      onTap: () async {
        final selectedDir = await FilePicker.platform
            .getDirectoryPath(dialogTitle: "Select your project directory");
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
    Get.snackbar(
        "Can't open file", "Not supported on ${Platform.operatingSystem}");
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
    Get.snackbar(
        "Can't open directory", "Not supported on ${Platform.operatingSystem}");
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
    Get.snackbar(
        "Can't open console", "Not supported on ${Platform.operatingSystem}");
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
    Get.snackbar(
        "Can't run file", "Not supported on ${Platform.operatingSystem}");
  }
}

/// Converts file2Text
Future<String> file2Text(File file) async {
  // TODO: unpack zip files
  final ext = p.extension(file.path);
  if (textFiles.contains(ext)) {
    return await file.readAsString();
  } else if (ext == ".pdf") {
    try {
      final document = pdf.PdfDocument(inputBytes: await file.readAsBytes());
      String text = pdf.PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      log("Couldn't extract from PDF: ${file.path}");
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

//TODO: direct modification in csv tables
