import 'dart:convert';
import 'dart:io';

import 'package:date_time_format/date_time_format.dart';
import "package:flutter/material.dart";
import 'package:get/get.dart';
import 'package:journal/db/dream.dart';
import 'package:journal/db/realm.dart';
import 'package:journal/views/editor.dart';
import 'package:journal/views/optional_features.dart';
import 'package:journal/views/realms/editor.dart';
import 'package:journal/widgets/editor.dart';
import 'package:date_time_format/date_time_format.dart';
import 'package:mdi/mdi.dart';
import 'package:objectdb/objectdb.dart';
import 'package:simple_markdown_editor/simple_markdown_editor.dart';

import '../../main.dart';

class RealmEditor extends StatelessWidget {
  final RealmEditMode mode;
  final RealmRecord? realm;
  const RealmEditor({ Key? key, required this.mode, this.realm }) : super(key: key);

  // PRO-TIP for VS Code: use Fold Level 4 to fold the BaseEditor fields
  // and Fold Level 5 for the children
  @override
  Widget build(BuildContext context) {
    return BaseEditor(
      defaultPage: mode == RealmEditMode.create ? "body" : null,
      initValues: () => {
        "title": TextEditingController(text: realm?.title ?? ""),
        "body": TextEditingController(text: realm?.body ?? ""),
        "_dreams": [],
        "_hasCompletedInitialFlow": false // mode == RealmEditMode.create
      },
      leftSide: (context) {final editor = BaseEditor.of(context)!; return [
        EditorRightPaneButton(ListTile(
          title: Text("Body"),
          subtitle: editor.values["title"].value.text.isNotEmpty
          ? Text(editor.values["title"].value.text) : Text("No title given yet"),
        ), "body"),
        // TODO: add character, setting, and history sections
        if (dreamList.isNotEmpty && mode == RealmEditMode.create) EditorRightPaneButton(ListTile(
          title: Text("Add dreams to this PR")
        ), "dreams"),
        if (mode == RealmEditMode.edit) ListTile(
          title: Text("Delete this entry", style: TextStyle(color: Colors.red)),
          trailing: Icon(Icons.delete, color: Colors.red),
          onTap: () async {
            var _do = await Get.dialog(AlertDialog(
              title: Text("Are you sure?"),
              content: Text("Are you sure you want to delete this journal entry? This isn't an action that should be taken lightly.\n"
              + "Further, once deleted, you do not get this entry back."),
              actions: [
                TextButton(onPressed: () => Get.back(result: true), child: Text("YES")),
                TextButton(onPressed: () => Get.back(result: false), child: Text("NO")),
              ],
            ));
            if (!_do) return;
            database.where((element) => element["realm"] == realm?.id).forEach((element) {
              final i = database.indexOf(element);
              database[i]["realm"] = null;
              database[i]["realm_canon"] = null;
            });
            await realm?.delete();
            Get.offAllNamed("/");
          },
        ),
      ];},
      leftSideTitle: Text("Persistent Realm"),
      rightSide: (context, pageName) {
        final editor = BaseEditor.of(context)!;
        if (pageName == "body") return Container(
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.topLeft,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TextField(
                controller: editor.values["title"],
                decoration: InputDecoration(
                  labelText: "Title",
                  hintText: "Titles help you distinguish dreams.",
                ),
                keyboardAppearance: Brightness.dark,
                keyboardType: TextInputType.text,
                maxLines: 1,
              ),
              Expanded(
                child: TextField(
                  controller: editor.values["body"],
                  decoration: InputDecoration(
                    alignLabelWithHint: true,
                    labelText: "Summary",
                    hintText: "Write more about a dream!",
                    border: InputBorder.none
                  ),
                  keyboardAppearance: Brightness.dark,
                  keyboardType: TextInputType.multiline,
                  minLines: null,
                  expands: true,
                  maxLines: null,
                  buildCounter: (BuildContext context, {required int currentLength, required bool isFocused, required int? maxLength}) {
                    if (isFocused) return Text(currentLength.toString());
                  }
                ),
              ),
              if (mode != RealmEditMode.edit && !editor.values["_hasCompletedInitialFlow"]) SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: mode == RealmEditMode.create ? OutlinedButton(
                    onPressed: () {
                      //editor.setValue("_hasCompletedInitialFlow", true);
                      editor.setActivePage("dreams");
                    },
                    child: Text("Continue")
                  ) : OutlinedButton(
                    onPressed: () {
                      editor.forceSave();
                    },
                    child: Text("Finish")
                  ),
                ),
              )
              // Expanded(
              //   child: MarkdownFormField(
              //     enableToolBar: true,
              //     controller: editor.values["body"],
              //     emojiConvert: true,
              //   )
              // )
            ],
          ),
        );
        if (pageName == "dreams") {
          final selectedDreamIds = editor.values["_dreams"];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemBuilder: (_, i) => dreamList[i].title == "" ? Container() : ListTile(
                      selected: selectedDreamIds.contains(dreamList[i].id),
                      title: Text(dreamList[i].title),
                      onTap: () => editor.setValue("_dreams", selectedDreamIds.contains(dreamList[i].id) 
                      ? (selectedDreamIds..remove(dreamList[i].id))
                      : (selectedDreamIds..add(dreamList[i].id))),
                    ),
                    itemCount: dreamList.length,
                  ),
                ),
                if (mode == RealmEditMode.create) SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      editor.forceSave();
                    },
                    child: Text("Finish")
                  ),
                )
              ],
            ),
          );
        }
      },
      rightSideTitle: (pageName) {
        if (pageName == "body") return Text("Body");
        if (pageName == "dreams") return Text("Add dreams");
      },
      onSave: (values) {
        // == CHECK
        if (values["title"].value.text.isEmpty) {
          Get.dialog(AlertDialog(
            title: Text("Title missing"),
            content: Text("You must title PRs. What better way to identify them?"),
            actions: [TextButton(child: Padding(padding: const EdgeInsets.all(8.0), child: Text("OK")), onPressed: () => Get.back())],
          ));
          return false;
        }

        // == SAVE
        final _id = realm?.id ?? ObjectId().hexString;
        var newData = {
          "_id": _id,
          "title": values["title"].value.text,
          "body": values["body"].value.text,
          //"timestamp": dateValue.millisecondsSinceEpoch,
        };
        for (var id in values["_dreams"]) {
          database.firstWhere((element) => element["_id"] == id)["realm"] = _id;
        }
        // final plotFile = File(platformStorageDir.absolute.path + "/lldj-plotlines/" + (newData["_id"] as String) + ".json");
        // if (OptionalFeatures.plotlines != PlotlineTypes.NONE && isPlotlinesEnabled) {
        //   if (plot != []) await plotFile.writeAsString(jsonEncode(plot.map<Map<String, String?>>((e) => {
        //     "body": e["body"],
        //     "subtitle": e["subtitle"]
        //   }).toList()));
        //   else if (plot == [] && await plotFile.exists()) {
        //     plotFile.delete();
        //   }
        // }
        if (mode == RealmEditMode.create) {
          realmDatabase.add(newData);
        } else {
          realmDatabase[realmDatabase.indexWhere((element) => element["_id"] == realm!.id)] = newData;
        }
        return true;
      },
    );
  }
}