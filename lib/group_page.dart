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
class GroupPage extends StatelessWidget {
  final Project project;
  final int groupIndex;
  final TextEditingController commentsController = TextEditingController();
  final TextEditingController submissionsController = TextEditingController();
  final savedIcon = const SavedIcon();
  GroupPage(this.project, this.groupIndex, {Key? key}) : super(key: key) {
    project.groupCommentFile(groupIndex).readAsString().then((value) {
      commentsController.text = value;
      savedController.grade.value = getGrade(value)?.nice() ?? "";
    });
    commentsController.addListener(() async {
      final comment = commentsController.text;
      await project.setGroupComment(groupIndex, comment);
      savedController.grade.value = getGrade(comment)?.nice() ?? "";
    });
  }

  to(int relativeIndex) async {
    project.currGroup += relativeIndex;
    if (project.currGroup <= -1) {
      Get.to(() => ProjectGroupsPage(project));
    } else if (project.currGroup >= project.groups.length) {
      Get.to(() => SubmitProjectPage(project));
    } else {
      Get.back();
      Get.to(() => GroupPage(project, project.currGroup));
    }
    project.save();
  }

  @override
  Widget build(BuildContext context) {
    Get.put(savedController);
    final submissionSide = DecoratedBox(
        decoration: BoxDecoration(
            border: Border.all(color: Colors.black12, width: 3),
            borderRadius: const BorderRadius.all(Radius.circular(5))),
        child: ListView(children: [
          for (final file in [
            for (final student in project.groups[groupIndex])
              ...student.submissionFiles
          ])
            ContextMenuArea(
              builder: (context) {
                return [
                  for (final util in fileUtils)
                    UtilContextMenuTile(util: util, file: file)
                ];
              },
              child: GFAccordion(
                collapsedTitleBackgroundColor:
                    Theme.of(context).dialogBackgroundColor,
                expandedTitleBackgroundColor: Theme.of(context).highlightColor,
                contentBackgroundColor: Theme.of(context).cardColor,
                titleChild: Row(
                  children: [
                    Text(p.basename(file.path)),
                    const Expanded(child: SizedBox()),
                    ...[
                      for (final util in fileUtils)
                        UtilButton(util: util, file: file)
                    ]
                  ],
                ),
                contentChild: SubmissionFileShower(file),
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
            Stack(alignment: AlignmentDirectional.bottomEnd, children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: savedIcon,
              ),
              CommentsTextField(controller: commentsController),
            ])
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

final savedController = GradeController();

class GradeController extends GetxController {
  Rx<String> grade = "".obs;
}

class SavedIcon extends StatelessWidget {
  const SavedIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Obx(() {
        final grade = Get.find<GradeController>().grade.value;
        final isValid = grade.isNotEmpty;
        return Text(isValid ? grade : "0",
            style: TextStyle(
                color: isValid ? Colors.green : Colors.red, fontSize: 16));
      });
}
