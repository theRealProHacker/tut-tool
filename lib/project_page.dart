import 'package:app/group_page.dart';
import 'package:app/home_page.dart';
import 'package:app/io.dart';
import 'package:app/logic.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Page to assemble groups
class ProjectGroupsPage extends StatefulWidget {
  final Project project;
  const ProjectGroupsPage(this.project, {Key? key}) : super(key: key);

  @override
  State<ProjectGroupsPage> createState() => _ProjectGroupsPageState();
}

class _ProjectGroupsPageState extends State<ProjectGroupsPage> {
  goTo(int x) async {
    final project = widget.project;
    project.currGroup = x;
    Get.to(() => GroupPage(project, x), transition: Transition.fade);
    await project.save();
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.project.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.to(() => const HomePage()),
        ),
      ),
      body: Stack(children: [
        Padding(
          padding: EdgeInsets.symmetric(
              vertical: 30,
              horizontal: MediaQuery.of(context).size.width * 0.1),
          child: Column(
            children: [
              // The command button row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                      style: ButtonStyle(
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.all(12))),
                      onPressed: () async {
                        setState(() => project.groups
                            .sort((a, b) => -a.length.compareTo(b.length)));
                        await project.save();
                      },
                      icon: const Icon(Icons.sort),
                      label: const Text("Sort",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20))),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                      style: ButtonStyle(
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.all(12))),
                      icon: const Icon(Icons.auto_awesome, color: Colors.amber),
                      label: const Text("Auto",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20)),
                      onPressed: (() async {
                        await autoGroups(project);
                        setState(() {
                          project.clean();
                        });
                        await project.save();
                      })),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                      style: ButtonStyle(
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.all(12))),
                      onPressed: () {
                        setState(() {
                          project.groups = [
                            for (final student in project.students) [student]
                          ];
                        });
                      },
                      icon: const Icon(Icons.restore/*, color: Colors.indigo*/),
                      label: const Text("Reset",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20)))
                ],
              ),
              const SizedBox(width: 0, height: 30),
              // The groups ListView
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.black12, width: 3),
                      borderRadius: const BorderRadius.all(Radius.circular(5))),
                  child: ListView(children: [
                    for (final group in widget.project.groups) ...[
                      DragTarget<Student>(
                          onAccept: (student) {
                            final index = group.indexOf(student);
                            if (index != -1) {
                              group.insert(index, student);
                            } else {
                              group.add(student);
                            }
                          },
                          builder: ((context, candidateData, rejectedData) =>
                              ListTile(
                                  onTap: () async => await goTo(
                                      widget.project.groups.indexOf(group)),
                                  title: Row(
                                    children: [
                                      for (final student in group)
                                        Draggable<Student>(
                                            data: student,
                                            onDragCompleted: (() async {
                                              setState(() {
                                                group.remove(student);
                                                widget.project.clean();
                                              });
                                              await widget.project.save();
                                            }),
                                            feedback: TextBox(
                                                student: student,
                                                project: widget.project),
                                            childWhenDragging: TextBox(
                                                student: student,
                                                project: widget.project),
                                            child: TextBox(
                                                student: student,
                                                project: widget.project)),
                                    ],
                                  ),
                                  trailing: widget.project.finishedGroups
                                          .contains(widget.project.groups
                                              .indexOf(group))
                                      ? const Icon(Icons.check,
                                          color: Colors.green)
                                      : const SizedBox()))),
                      const Divider()
                    ]
                  ]),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

/// A TextBox that is for dragging Text
class TextBox extends StatelessWidget {
  const TextBox({Key? key, required this.student, required this.project})
      : super(key: key);

  final Student student;
  final Project project;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DecoratedBox(
        decoration: BoxDecoration(
            border: Border.all(
                color: student.didSubmit ? Colors.black54 : Colors.black26,
                width: 3)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(student.displayName),
        ),
      ),
    );
  }
}

class SubmitProjectPage extends StatefulWidget {
  final Project project;
  const SubmitProjectPage(this.project, {Key? key}) : super(key: key);

  @override
  State<SubmitProjectPage> createState() => _SubmitProjectPageState();
}

class _SubmitProjectPageState extends State<SubmitProjectPage> {
  goTo(int x) async {
    widget.project.currGroup = x;
    Get.to(() => GroupPage(widget.project, x), transition: Transition.fade);
    await widget.project.save();
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text("Submit ${project.name}"),
        ),
        body: Padding(
            padding: EdgeInsets.symmetric(
                vertical: 30,
                horizontal: MediaQuery.of(context).size.width * 0.1),
            child: FutureBuilder(
              future: () async {
                final comments = await Future.wait([
                  for (final group in project.groups)
                    project
                        .groupComments(project.groupIndex(group))
                        .readAsString()
                ]);
                return [for (final comment in comments) getGrade(comment) ?? 0];
              }(),
              initialData: List.filled(widget.project.groups.length, null),
              builder: (context, snapshot) => Column(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                        onPressed: snapshot.hasData
                            ? () async {
                                // Set grades
                                // TODO: read, enter grade, then write
                                // Not read, enter, write, read, enter, write, read, enter, write, ...
                                final failed = [
                                  for (final pair
                                      in zip(project.groups, snapshot.data!))
                                    for (final student in pair.first)
                                      await student.setGrade(pair.second!)
                                ].where((e) => e != null);
                                if (failed.isNotEmpty) {
                                  Get.bottomSheet(Container(
                                      decoration: const BoxDecoration(
                                          color: Colors.white),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                            'Failed for: ${failed.join(", ")}'),
                                      )));
                                }
                                // Zip
                                final file = await zipDir(project.dir);
                                openDir(file);
                              }
                            : null,
                        icon: const Icon(Icons.upload),
                        label: const Text(
                          "Submit",
                          style: TextStyle(fontSize: 20),
                        )),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12, width: 3),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(5))),
                      child: ListView(children: [
                        for (final pair
                            in zip(widget.project.groups, snapshot.data!)) ...[
                          () {
                            final group = pair.first;
                            final grade = pair.second;
                            final trailingColor = widget.project.finishedGroups
                                        .contains(widget.project.groups
                                            .indexOf(group)) ||
                                    !group.any((student) =>
                                        student.submissionFiles.isNotEmpty)
                                ? Colors.green
                                : Colors.red;
                            final trailing = grade != null
                                ? Text(
                                    niceDouble(grade),
                                    style: TextStyle(color: trailingColor),
                                  )
                                : const Text("Loading ...");
                            return ListTile(
                              onTap: () async => await goTo(
                                  widget.project.groups.indexOf(group)),
                              title: Row(
                                children: [
                                  for (final student in group)
                                    TextBox(
                                        student: student,
                                        project: widget.project)
                                ],
                              ),
                              trailing: trailing,
                            );
                          }(),
                          const Divider()
                        ]
                      ]),
                    ),
                  ),
                ],
              ),
            )));
  }
}
