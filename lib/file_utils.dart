import 'package:app/io.dart';
import 'package:flutter/material.dart';
import 'dart:io';

typedef FileUtilFunction = void Function(File file);

class FileUtil {
  final String name;
  final Widget icon;
  final FileUtilFunction func;

  const FileUtil(this.name, {required this.icon, required this.func});
}

const terminalUtil =
    FileUtil("Terminal", icon: Icon(Icons.terminal), func: consoleDir);
const opendirUtil =
    FileUtil("Open directory", icon: Icon(Icons.folder), func: openDir);
const openfileUtil =
    FileUtil("Open file", icon: Icon(Icons.file_open), func: openFile);
const runfileUtil =
    FileUtil("Run file", icon: Icon(Icons.play_arrow), func: runFile);

class UtilButton extends StatelessWidget {
  final File file;
  final FileUtil util;
  const UtilButton({Key? key, required this.util, required this.file})
      : super(key: key);

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
  const UtilContextMenuTile({Key? key, required this.util, required this.file})
      : super(key: key);

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
        /// XXX: To close the ContextMenu
        Navigator.of(context).pop();
        util.func(file);
      },
    );
  }
}
