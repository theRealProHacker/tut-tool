import 'package:app/group_page.dart';
import 'package:app/home_page.dart';
import 'package:app/logic.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'io.dart';

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
    await project.setCurrGroup(x);
    Get.to(() => GroupPage(project, x), transition: Transition.fade);
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
        actions: [
          IconButton(
              tooltip: "template".tr,
              onPressed: () {
                Get.to(() => CommentsTemplatePage(project));
              },
              icon: const Icon(Icons.map)),
          const SizedBox(width: 20)
        ],
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
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(12)),
                      onPressed: () async {
                        await project.sort();
                        setState(() {});
                      },
                      icon: const Icon(Icons.sort),
                      label: Text("sort".tr,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20))),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(12)),
                      icon: const Icon(Icons.auto_awesome, color: Colors.amber),
                      label: Text("auto".tr,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20)),
                      onPressed: (() async {
                        await autoGroups(project);
                        await project.sort();
                        setState(() {
                          project.clean();
                        });
                        await project.save();
                      })),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(12)),
                      onPressed: () async {
                        await project.reset();
                        setState(() {});
                      },
                      icon: const Icon(Icons.restore),
                      label: Text("reset".tr,
                          style: const TextStyle(
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
                    for (final entry in project.groups.asMap().entries)
                      ...() {
                        final index = entry.key;
                        final group = entry.value;
                        return [
                          DragTarget<Student>(
                            onAccept: (student) {
                              group.add(student);
                            },
                            builder: ((context, candidateData, rejectedData) =>
                                ListTile(
                                    onTap: () async => await goTo(index),
                                    title: Row(
                                      children: [
                                        for (final student in group)
                                          Draggable<Student>(
                                              data: student,
                                              onDragCompleted: (() async {
                                                setState(() {
                                                  group.remove(student);
                                                  project.clean();
                                                });
                                                await project.save();
                                              }),
                                              feedback: TextBox(
                                                  student: student,
                                                  project: project),
                                              childWhenDragging: TextBox(
                                                  student: student,
                                                  project: project),
                                              child: TextBox(
                                                  student: student,
                                                  project: project)),
                                      ],
                                    ),
                                    trailing: Tooltip(
                                      message: "expand".tr,
                                      child: ElevatedButton.icon(
                                          onPressed: () {
                                            final groups = project.groups;
                                            groups.insertAll(index, [
                                              for (final student in group)
                                                [student]
                                            ]);
                                            setState(() {
                                              groups.remove(group);
                                            });
                                          },
                                          icon: const Icon(Icons
                                              .keyboard_arrow_down_outlined),
                                          label: const SizedBox()),
                                    ))),
                          ),
                          const Divider()
                        ];
                      }()
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

/// A TextBox for draggable Text
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
    final project = widget.project;
    await project.setCurrGroup(x);
    Get.to(() => GroupPage(project, x), transition: Transition.fade);
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text("submit_project".trParams({"project": project.name})),
        ),
        body: Padding(
            padding: EdgeInsets.symmetric(
                vertical: 30,
                horizontal: MediaQuery.of(context).size.width * 0.1),
            child: FutureBuilder(
              future: () async {
                return await Future.wait([
                  for (final index in Iterable.generate(project.groups.length))
                    project.groupGrade(index)
                ]);
              }(),
              initialData: List.filled(widget.project.groups.length, null),
              builder: (context, snapshot) {
                // Default grade is zero
                final realGrades = [
                  for (final grade in snapshot.data!) grade ?? 0
                ];
                return Column(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton.icon(
                          onPressed: snapshot.hasData
                              ? () async => await project
                                  .submit(zip(project.groups, realGrades))
                              : null,
                          icon: const Icon(Icons.upload),
                          label: Text(
                            "submit".tr,
                            style: const TextStyle(fontSize: 20),
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
                          for (final pair in zip(
                              widget.project.groups, snapshot.data!)) ...[
                            () {
                              final group = pair.first;
                              final grade = pair.second;
                              final trailing = snapshot.hasData
                                  ? Text(
                                      'Grade: ${grade?.nice() ?? "None"}',
                                      style: TextStyle(
                                          // red if group submitted but has no grade
                                          color: grade == null &&
                                                  didGroupSubmit(group)
                                              ? Colors.red
                                              : Colors.green,
                                          fontSize: 16),
                                    )
                                  : Text("loading".tr);
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
                );
              },
            )));
  }
}

class CommentsTemplatePage extends StatelessWidget {
  final Project project;
  final TextEditingController controller;
  CommentsTemplatePage(this.project, {Key? key})
      : controller = TextEditingController(text: project.commentsTemplate),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text("comment_template".tr)),
      body: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Row(
          children: [
            const Expanded(child: SizedBox()),
            Expanded(
                flex: 1,
                child: Column(
                  children: [
                    CommentsTextField(controller: controller),
                    const SizedBox(height: 30),
                    ElevatedButton(
                        onPressed: () async {
                          await project.setCommentsTemplate(controller.text);
                          Get.back();
                        },
                        child: Text("apply_template".tr))
                  ],
                )),
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }
}
