import 'dart:io';

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
  GroupPage(this.project, this.groupIndex, {super.key}) {
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

  Future<void> to(int relativeIndex) async {
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
            FutureBuilder(
              future: () async {
                final feedbackFile = File(p.join(
                    p.dirname(p.dirname(file.absolute.path)),
                    feedbackAttachments,
                    p.basename(file.path)));
                return await feedbackFile.exists() ? feedbackFile : file;
              }(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final file = snapshot.data!;
                return ContextMenuArea(
                  builder: (context) {
                    return [
                      for (final util in fileUtils)
                        UtilContextMenuTile(util: util, file: file)
                    ];
                  },
                  child: GFAccordion(
                    collapsedTitleBackgroundColor:
                        Theme.of(context).dialogBackgroundColor,
                    expandedTitleBackgroundColor:
                        Theme.of(context).highlightColor,
                    contentBackgroundColor: Theme.of(context).cardColor,
                    titleChild: Row(
                      children: [
                        Expanded(
                          child: _EllipsizedFilename(p.basename(file.path)),
                        ),
                        ...[
                          for (final util in fileUtils)
                            UtilButton(util: util, file: file)
                        ]
                      ],
                    ),
                    contentChild: SubmissionFileShower(file),
                  ),
                );
              },
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
      body: FutureBuilder(
        future: getMonitorSize(),
        initialData: const Size(0, 0),
        builder: (context, snapshot) => Stack(children: [
          // The idea is to only show the submissionSide when
          // the windows width > half of the screens width
          // on desktop OSs
          Padding(
              padding: const EdgeInsets.all(60.0),
              child: snapshot.hasData &&
                      MediaQuery.of(context).size.width >
                          snapshot.data!.width / 2
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
      ),
    );
  }
}

final savedController = GradeController();

class GradeController extends GetxController {
  Rx<String> grade = "".obs;
}

class SavedIcon extends StatelessWidget {
  const SavedIcon({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
        final grade = Get.find<GradeController>().grade.value;
        final isValid = grade.isNotEmpty;
        return Text(isValid ? grade : "0",
            style: TextStyle(
                color: isValid ? Colors.green : Colors.red, fontSize: 16));
      });
}

/// A widget that displays a filename with middle ellipsis if too long,
/// always preserving the file extension.
class _EllipsizedFilename extends StatelessWidget {
  final String filename;

  const _EllipsizedFilename(this.filename);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final style = DefaultTextStyle.of(context).style;
        final textPainter = TextPainter(
          text: TextSpan(text: filename, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: double.infinity);

        // If the text fits, just display it normally
        if (textPainter.width <= constraints.maxWidth) {
          return Text(filename);
        }

        // Split into name and extension
        final extension = p.extension(filename);
        final nameWithoutExt = p.basenameWithoutExtension(filename);

        // Measure the extension + ellipsis
        final ellipsis = '…';
        final suffixPainter = TextPainter(
          text: TextSpan(text: '$ellipsis$extension', style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: double.infinity);

        final availableWidthForName =
            constraints.maxWidth - suffixPainter.width;

        // Find how many characters of the name we can fit
        String truncatedName = '';
        for (int i = 1; i <= nameWithoutExt.length; i++) {
          final testName = nameWithoutExt.substring(0, i);
          final testPainter = TextPainter(
            text: TextSpan(text: testName, style: style),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: double.infinity);

          if (testPainter.width > availableWidthForName) {
            break;
          }
          truncatedName = testName;
        }

        // If we can't fit even one character, just show ellipsis + extension
        final displayText = truncatedName.isEmpty
            ? '$ellipsis$extension'
            : '$truncatedName$ellipsis$extension';

        return Text(displayText);
      },
    );
  }
}
