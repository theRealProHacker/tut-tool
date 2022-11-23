import 'package:app/file_utils.dart';
import 'package:app/io.dart';
import 'package:app/project_page.dart';
import 'package:contextmenu/contextmenu.dart';
import 'package:flutter/material.dart';

import 'package:path/path.dart' as p;
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';

import 'package:app/logic.dart';

/// Single Group Page for grading
class GroupPage extends StatefulWidget {
  final Project project;
  final int groupIndex;
  const GroupPage(this.project, this.groupIndex, {Key? key}) : super(key: key);

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  TextEditingController controller = TextEditingController();

  to(int relativeIndex) async {
    final project = widget.project;
    final groupIndex = widget.groupIndex;
    if (controller.text.isNotEmpty) {
      await Future.wait([
        for (final student in project.groups[groupIndex])
          student.commentsFile.writeAsString(controller.text, flush: true)
      ]);
    }
    project.currGroup += relativeIndex;
    if (project.currGroup <= -1) {
      Get.to(() => ProjectGroupsPage(project));
    } else if (project.currGroup >= project.groups.length) {
      Get.to(() => SubmitProjectPage(project));
    } else {
      Get.back();
      Get.to(GroupPage(project, project.currGroup));
    }
    project.save();
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final groupIndex = widget.groupIndex;
    widget.project.groupComments(groupIndex).readAsString().then(((value) {
      controller.text = value;
    }));
    final submissionSide = DecoratedBox(
        decoration: BoxDecoration(
            border: Border.all(color: Colors.black12, width: 3),
            borderRadius: const BorderRadius.all(Radius.circular(5))),
        child: ListView(children: [
          for (final file in [
            for (final student in widget.project.groups[groupIndex])
              ...student.submissionFiles
          ])
            ContextMenuArea(
              builder: (context) {
                return [
                  for (final util in [
                    terminalUtil,
                    opendirUtil,
                    openfileUtil,
                    runfileUtil
                  ])
                    UtilContextMenuTile(util: util, file: file)
                ];
              },
              child: GFAccordion(
                collapsedTitleBackgroundColor: Theme.of(context).dialogBackgroundColor,
                expandedTitleBackgroundColor: Theme.of(context).highlightColor,
                contentBackgroundColor: Theme.of(context).cardColor,
                titleChild: Row(
                  children: [
                    Text(p.basename(file.path)),
                    const Expanded(child: SizedBox()),
                    ...[
                      for (final util in [
                        terminalUtil,
                        opendirUtil,
                        openfileUtil,
                        runfileUtil
                      ])
                        UtilButton(util: util, file: file)
                    ]
                  ],
                ),
                contentChild: FileShower(file),
              ),
            )
        ]));
    final feedbackSide = DecoratedBox(
      decoration: BoxDecoration(
          border: Border.all(color: Colors.black12, width: 3),
          borderRadius: const BorderRadius.all(Radius.circular(5))),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(
                  labelText: "Comments",
                  alignLabelWithHint: true,
                  border: OutlineInputBorder()),
              controller: controller,
              maxLines: 20,
              minLines: 5,
              cursorRadius: const Radius.circular(5),
              // readOnly: loading,
            )
          ],
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(project.groupTitle(groupIndex)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async => await to(-project.currGroup - 1),
        ),
        actions: [
          IconButton(
              onPressed: () async =>
                  await to(project.groups.length - project.currGroup),
              icon: const Icon(Icons.arrow_forward))
        ],
      ),
      body: Stack(children: [
        Padding(
            padding: const EdgeInsets.all(60.0),
            child: MediaQuery.of(context).size.width > 1400
                ? Row(
                    children: [
                      Expanded(child: submissionSide),
                      const SizedBox(width: 30),
                      Expanded(child: feedbackSide)
                    ],
                  )
                : feedbackSide),
        Align(
            alignment: Alignment.centerLeft,
            child: Flex(
              mainAxisAlignment: MainAxisAlignment.center,
              direction: Axis.vertical,
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: Theme.of(context).appBarTheme.backgroundColor),
                    child: IconButton(
                      splashRadius: null,
                      icon: const Icon(Icons.arrow_left_outlined),
                      onPressed: () async => await to(-1),
                    ),
                  ),
                ),
              ],
            )),
        Align(
            alignment: Alignment.centerRight,
            child: Flex(
              mainAxisAlignment: MainAxisAlignment.center,
              direction: Axis.vertical,
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: Theme.of(context).appBarTheme.backgroundColor),
                    child: IconButton(
                      splashRadius: null,
                      icon: const Icon(Icons.arrow_right_outlined),
                      onPressed: () async => await to(1),
                    ),
                  ),
                ),
              ],
            )),
      ]),
    );
  }
}
