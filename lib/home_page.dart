import 'package:app/group_page.dart';
import 'package:app/logic.dart';
import 'package:app/project_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app/new_project_page.dart';
import 'package:app/settings_page.dart';

// The Home Page that shows the project list
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("home".tr),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Get.to(() => const SettingsPage());
              },
            ),
            const SizedBox(width: 10)
          ],
        ),
        drawer: const HomeDrawer(),
        body: Center(
            child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
              border: Border.all(width: 1, color: Colors.black26)),
          constraints: BoxConstraints.loose(const Size(800, 500)),
          child: const ProjectList(),
        )));
  }
}

/// The Drawer on the HomeScreen
class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Text("menu".tr,
                style: const TextStyle(fontSize: 30, color: Colors.white))),
        AboutListTile(
          icon: const Icon(Icons.info_outline_rounded),
          applicationVersion: "0.0.1",
          aboutBoxChildren: const <Widget>[
            SizedBox(height: 86, child: Text("Joking")),
            SizedBox(height: 24),
          ],
          child: Text("about".tr),
        )
      ],
    ));
  }
}

/// A list that shows all Projects
class ProjectList extends StatelessWidget {
  const ProjectList({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Project> projects = projC.projects;

    return Obx(
      () => Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
                projC.reorderProject(oldIndex, newIndex);
              },
              itemCount: projects.length,
              itemBuilder: (context, index) => ListTile(
                key: ValueKey(projects[index]),
                leading: ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                ),
                title: Text(projects[index].name),
                trailing: Tooltip(
                  message: "delete".tr,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white60,
                          foregroundColor: Colors.black87),
                      onPressed: (() => projC.removeProjectAt(index)),
                      child: const Icon(Icons.delete)),
                ),
                onTap: (() {
                  final project = projects[index];
                  if (project.currGroup >= 0 &&
                      project.currGroup < project.groups.length) {
                    Get.to(() => GroupPage(project, project.currGroup));
                  } else if (project.currGroup == -1) {
                    Get.to(() => ProjectGroupsPage(project));
                  } else {
                    Get.to(() => SubmitProjectPage(project));
                  }
                }),
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add),
            title: Text("create_project".tr),
            onTap: () =>
                Get.to(() => NewProjectPage(), transition: Transition.fadeIn),
          ),
        ],
      ),
    );
  }
}
