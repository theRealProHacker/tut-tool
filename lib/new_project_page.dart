import 'package:app/logic.dart';
import 'package:app/io.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Page to create a new project
class NewProjectPage extends StatelessWidget {
  NewProjectPage({super.key});
  final nameController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final dirInput = DirInput();
    return Scaffold(
        appBar: AppBar(centerTitle: true, title: Text("new_project".tr)),
        body: Center(
          child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 100, vertical: 30),
              decoration: BoxDecoration(
                  border: Border.all(width: 1, color: Colors.black26)),
              constraints: BoxConstraints.loose(const Size(800, 500)),
              child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      TextFormField(
                          autofocus: true,
                          controller: nameController,
                          decoration: InputDecoration(label: Text("name".tr)),
                          validator: (value) =>
                              value!.isEmpty ? "enter_name".tr : null,
                          style: const TextStyle(fontSize: 20)),
                      SizedBox.fromSize(
                        size: const Size(0, 30),
                      ),
                      dirInput,
                      SizedBox.fromSize(
                        size: const Size(0, 30),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.fromLTRB(12, 15, 15, 15),
                            textStyle: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w400)),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            projC.addProject(Project.add(
                                nameController.text, dirInput.value));
                            Get.back();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: Text('create'.tr),
                      ),
                    ],
                  ))),
        ));
  }
}
