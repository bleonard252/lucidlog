import "package:flutter/material.dart";
import 'package:get/get.dart';
import 'package:journal/main.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart' as Settings;

class MethodsSettingsScreen extends StatefulWidget {

  const MethodsSettingsScreen({ Key? key }) : super(key: key);

  @override
  _MethodsSettingsScreenState createState() => _MethodsSettingsScreenState();
}

class _MethodsSettingsScreenState extends State<MethodsSettingsScreen> {
  late final List<String> methods;
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    methods = sharedPreferences.getStringList("ld-methods") ?? [];
    super.initState();
  }

  @override
  void dispose() {
    sharedPreferences.setStringList("ld-methods", methods);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Settings.SettingsToggleScreen(
      title: "Techniques",
      settingKey: "opt-methods",
      defaultValue: false,
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          itemBuilder: (context, index) => ListTile(
            key: ValueKey("METHOD:"+methods[index]),
            title: Text(methods[index]),
            trailing: Padding(
              padding: GetPlatform.isDesktop ? const EdgeInsets.symmetric(horizontal: 24.0) : EdgeInsets.all(0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      setState(() => methods.remove(methods[index]));
                    },
                  ),
                  if (GetPlatform.isMobile) Icon(Icons.drag_handle, color: Get.iconColor?.withAlpha(128))
                ],
              ),
            ),
          ), 
          itemCount: methods.length,
          onReorder: (oldIndex, newIndex) {
            final method = methods[oldIndex];
            if(newIndex > oldIndex){
              newIndex -= 1;
            }
            methods.removeAt(oldIndex);
            methods.insert(newIndex, method);
          }
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: "Add a new technique with comma (,) or Enter"
            ),
            onChanged: (v) {
              if (v.endsWith(",")) {
                if (v.replaceFirst(",", "") != "") methods.add(v.replaceFirst(",", ""));
                controller.clear();
                setState(() {});
              }
            },
            onEditingComplete: () {
              if (controller.value.text.isNotEmpty) methods.add(controller.value.text.replaceFirst(",", ""));
              controller.clear();
              setState(() {});
            },
          ),
        )
      ]
    );
  }
}