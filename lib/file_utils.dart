import 'package:app/io.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:get/get.dart';

typedef FileUtilFunction = void Function(File file);

class FileUtil {
  final String name;
  final Widget icon;
  final FileUtilFunction func;

  const FileUtil(this.name, {required this.icon, required this.func});
}

final terminalUtil =
    FileUtil("terminal".tr, icon: const Icon(Icons.terminal), func: consoleDir);
final opendirUtil = FileUtil("open_directory".tr,
    icon: const Icon(Icons.folder), func: openDir);
final openfileUtil =
    FileUtil("open_file".tr, icon: const Icon(Icons.file_open), func: openFile);
final runfileUtil =
    FileUtil("run_file".tr, icon: const Icon(Icons.play_arrow), func: runFile);

/// The list of file utilities
final fileUtils = [terminalUtil, opendirUtil, openfileUtil, runfileUtil];

class UtilButton extends StatelessWidget {
  final File file;
  final FileUtil util;
  const UtilButton({super.key, required this.util, required this.file});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => util.func(file),
      icon: util.icon,
      tooltip: util.name,
    );
  }
}

class UtilContextMenuTile extends StatelessWidget {
  final File file;
  final FileUtil util;
  const UtilContextMenuTile({super.key, required this.util, required this.file});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          util.icon,
          const SizedBox(
            width: 15,
          ),
          Text(util.name)
        ],
      ),
      onTap: () {
        // XXX: To close the ContextMenu
        Navigator.of(context).pop();
        util.func(file);
      },
    );
  }
}
