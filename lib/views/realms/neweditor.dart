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

// ignore: must_be_immutable
class RealmEditor extends StatelessWidget {
  final RealmEditMode mode;
  final RealmRecord? realm;
  late final charsethist;
  bool _charsethistLoaded = false;
  RealmEditor({ Key? key, required this.mode, this.realm }) : super(key: key);

  mapCharsethist(value) => {
    "title": TextEditingController(text: value["title"]!),
    "body": TextEditingController(text: value["body"]!)
  };

  // PRO-TIP for VS Code: use Fold Level 4 to fold the BaseEditor fields
  // and Fold Level 5 for the children
  @override
  Widget build(BuildContext context) {
    if (!_charsethistLoaded) {
      if (realm?.extraFile.existsSync()??false) {
        charsethist = jsonDecode(realm!.extraFile.readAsStringSync());
      } else {
        charsethist = {};
      }
      _charsethistLoaded = true;
    }
    return BaseEditor(
      defaultPage: mode == RealmEditMode.create ? "body" : null,
      initValues: () => {
        "title": TextEditingController(text: realm?.title ?? ""),
        "body": TextEditingController(text: realm?.body ?? ""),
        "characters": charsethist["characters"]?.map(mapCharsethist).toList() ?? [],
        "settings": charsethist["settings"]?.map(mapCharsethist).toList() ?? [],
        "history": charsethist["history"]?.map(mapCharsethist).toList() ?? [],
        "_dreams": [],
        "_hasCompletedInitialFlow": false // mode == RealmEditMode.create
      },
      leftSide: (context) {final editor = BaseEditor.of(context)!; return [
        EditorRightPaneButton(ListTile(
          title: Text("Body"),
          subtitle: editor.values["title"].value.text.isNotEmpty
          ? Text(editor.values["title"].value.text) : Text("No title given yet"),
        ), "body"),
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
        // TODO: add character, setting, and history sections
        ...[ // Characters
          Padding(
            padding: const EdgeInsets.all(8.0).copyWith(top: 24.0),
            child: Row(
              children: [
                Text(
                  "CHARACTERS", // Protip: use Dismissable widgets for these items!
                  style: TextStyle(color: Get.theme.primaryColor, fontWeight: FontWeight.bold),
                ),
                Expanded(child: Container()),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    onPressed: () => Get.dialog(AlertDialog(
                      title: Text("How to best use these lists"),
                      content: Text("Swipe left or right to delete the entry.\n"
                      "Press and hold, then drag up and down to reorder the entries."),
                      actions: [TextButton(child: Padding(padding: const EdgeInsets.all(8.0), child: Text("OK")), onPressed: () => Get.back())],
                    )),
                    icon: Icon(Icons.help_outline),
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightForFinite(height: 24),
                  ),
                ),
                IconButton(
                  onPressed: () => editor.setValue("characters",
                    (editor.values["characters"] as List)
                    ..add({
                      "body": TextEditingController(),
                      "title": TextEditingController()
                    })
                  ),
                  icon: Icon(Mdi.accountPlus),
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tightForFinite(height: 24),
                )
              ],
            ),
          ),
          ReorderableListView(
            shrinkWrap: true,
            buildDefaultDragHandles: false,
            children: [
              for (var character in editor.values["characters"]) Dismissible(
                key: ObjectKey(character),
                child: ReorderableDelayedDragStartListener(
                  index: editor.values["characters"].indexOf(character),
                  child: EditorRightPaneButton(ListTile(
                    title: character["title"].value.text.isNotEmpty
                    ? Text(character["title"].value.text)
                    : Text("No name given"),
                    subtitle: character["body"].value.text.isNotEmpty
                    ? Text(character["body"].value.text, maxLines: 1, overflow: TextOverflow.ellipsis)
                    : Text("No summary given"),
                  ), "sub:characters:"+(editor.values["characters"].indexOf(character).toString())),
                ),
                background: Container(color:Colors.red, child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Icon(Icons.delete),
                ), alignment: Alignment.centerLeft),
                secondaryBackground: Container(color:Colors.red, child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Icon(Icons.delete),
                ), alignment: Alignment.centerRight),
                onDismissed: (_) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  final _index = editor.values["characters"].indexOf(character);
                  editor.setValue("characters", editor.values["characters"]..remove(character));
                  var name = character["title"].value.text;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("""The "$name" character has been removed."""),
                    action: SnackBarAction(
                      label: "UNDO",
                      onPressed: () => editor.setValue("characters", editor.values["characters"]..insert(_index, character)),
                    ),
                    duration: Duration(seconds: 7),
                  ));
                },
              )
            ], 
            onReorder: (oldPos, newPos) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              if (oldPos < newPos) newPos -= 1;
              var characters = editor.values["characters"];
              final oldItem = characters.removeAt(oldPos);
              characters.insert(newPos, oldItem);
              if (editor.activePage?.startsWith("characters") ?? false) editor.setActivePage(null, true);
              editor.setValue("characters", characters);
            }
          )
        ],
        ...[ // Settings
          Padding(
            padding: const EdgeInsets.all(8.0).copyWith(top: 24.0),
            child: Row(
              children: [
                Text(
                  "SETTINGS", // Protip: use Dismissable widgets for these items!
                  style: TextStyle(color: Get.theme.primaryColor, fontWeight: FontWeight.bold),
                ),
                Expanded(child: Container()),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    onPressed: () => Get.dialog(AlertDialog(
                      title: Text("What is a setting?"),
                      content: Text("A \"setting\" is any place and/or time in which something is set.\n"
                      "For the purposes of PRs, this is most likely going to be a place of some sort, but it could be tied to a specific time that this place is always/only seen in,"
                      " such as a holiday-related place or somewhere you only go at night."),
                      actions: [TextButton(child: Padding(padding: const EdgeInsets.all(8.0), child: Text("OK")), onPressed: () => Get.back())],
                    )),
                    icon: Icon(Icons.help_outline),
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightForFinite(height: 24),
                  ),
                ),
                IconButton(
                  onPressed: () => editor.setValue("settings",
                    (editor.values["settings"] as List)
                    ..add({
                      "body": TextEditingController(),
                      "title": TextEditingController()
                    })
                  ),
                  icon: Icon(Mdi.mapMarkerPlus),
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tightForFinite(height: 24),
                )
              ],
            ),
          ),
          ReorderableListView(
            shrinkWrap: true,
            buildDefaultDragHandles: false,
            children: [
              for (var setting in editor.values["settings"]) Dismissible(
                key: ObjectKey(setting),
                child: ReorderableDelayedDragStartListener(
                  index: editor.values["settings"].indexOf(setting),
                  child: EditorRightPaneButton(ListTile(
                    title: setting["title"].value.text.isNotEmpty
                    ? Text(setting["title"].value.text)
                    : Text("No name given"),
                    subtitle: setting["body"].value.text.isNotEmpty
                    ? Text(setting["body"].value.text, maxLines: 1, overflow: TextOverflow.ellipsis)
                    : Text("No summary given"),
                  ), "sub:settings:"+(editor.values["settings"].indexOf(setting).toString())),
                ),
                background: Container(color:Colors.red, child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Icon(Icons.delete),
                ), alignment: Alignment.centerLeft),
                secondaryBackground: Container(color:Colors.red, child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Icon(Icons.delete),
                ), alignment: Alignment.centerRight),
                onDismissed: (_) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  final _index = editor.values["settings"].indexOf(setting);
                  editor.setValue("settings", editor.values["settings"]..remove(setting));
                  var name = setting["title"].value.text;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("""The "$name" setting has been removed."""),
                    action: SnackBarAction(
                      label: "UNDO",
                      onPressed: () => editor.setValue("settings", editor.values["settings"]..insert(_index, setting)),
                    ),
                    duration: Duration(seconds: 7),
                  ));
                },
              )
            ], 
            onReorder: (oldPos, newPos) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              if (oldPos < newPos) newPos -= 1;
              var settings = editor.values["settings"];
              final oldItem = settings.removeAt(oldPos);
              settings.insert(newPos, oldItem);
              if (editor.activePage?.startsWith("settings") ?? false) editor.setActivePage(null, true);
              editor.setValue("settings", settings);
            }
          )
        ],
        ...[ // History
          Padding(
            padding: const EdgeInsets.all(8.0).copyWith(top: 24.0),
            child: Row(
              children: [
                Text(
                  "HISTORY", // Protip: use Dismissable widgets for these items!
                  style: TextStyle(color: Get.theme.primaryColor, fontWeight: FontWeight.bold),
                ),
                Expanded(child: Container()),
                IconButton(
                  onPressed: () => editor.setValue("history",
                    (editor.values["history"] as List)
                    ..add({
                      "body": TextEditingController(),
                      "title": TextEditingController()
                    })
                  ),
                  icon: Icon(Mdi.bookPlus),
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tightForFinite(height: 24),
                )
              ],
            ),
          ),
          ReorderableListView(
            shrinkWrap: true,
            buildDefaultDragHandles: false,
            children: [
              for (var event in editor.values["history"]) Dismissible(
                key: ObjectKey(event),
                child: ReorderableDelayedDragStartListener(
                  index: editor.values["history"].indexOf(event),
                  child: EditorRightPaneButton(ListTile(
                    title: event["title"].value.text.isNotEmpty
                    ? Text(event["title"].value.text)
                    : Text("No name given"),
                    subtitle: event["body"].value.text.isNotEmpty
                    ? Text(event["body"].value.text, maxLines: 1, overflow: TextOverflow.ellipsis)
                    : Text("No summary given"),
                  ), "sub:history:"+(editor.values["history"].indexOf(event).toString())),
                ),
                background: Container(color:Colors.red, child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Icon(Icons.delete),
                ), alignment: Alignment.centerLeft),
                secondaryBackground: Container(color:Colors.red, child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Icon(Icons.delete),
                ), alignment: Alignment.centerRight),
                onDismissed: (_) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  final _index = editor.values["history"].indexOf(event);
                  editor.setValue("history", editor.values["history"]..remove(event));
                  var name = event["title"].value.text;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("""The "$name" history event has been removed."""),
                    action: SnackBarAction(
                      label: "UNDO",
                      onPressed: () => editor.setValue("history", editor.values["history"]..insert(_index, event)),
                    ),
                    duration: Duration(seconds: 7),
                  ));
                },
              )
            ], 
            onReorder: (oldPos, newPos) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              if (oldPos < newPos) newPos -= 1;
              var history = editor.values["history"];
              final oldItem = history.removeAt(oldPos);
              history.insert(newPos, oldItem);
              if (editor.activePage?.startsWith("history") ?? false) editor.setActivePage(null, true);
              editor.setValue("history", history);
            }
          )
        ],
        
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
        if (pageName.startsWith("sub:")) {
          final _parts = pageName.split(":");
          final type = _parts[1];
          final i = int.parse(_parts[2]);
          return Container(
            padding: const EdgeInsets.all(8.0),
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextField(
                  controller: editor.values[type][i]["title"],
                  decoration: InputDecoration(
                    labelText: type == "character" ? "Name" : "Title",
                    //hintText: "Titles help you distinguish dreams.",
                  ),
                  keyboardAppearance: Brightness.dark,
                  keyboardType: TextInputType.text,
                  maxLines: 1,
                ),
                Expanded(
                  child: TextField(
                    controller: editor.values[type][i]["body"],
                    decoration: InputDecoration(
                      alignLabelWithHint: true,
                      labelText: "Summary",
                      //hintText: "Write more about a dream!",
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
        if (values["characters"].any((v) => v["title"].value.text.isEmpty || v["body"].value.text.isEmpty)) {
          Get.dialog(AlertDialog(
            title: Text("Character details missing"),
            content: Text("One of your PR's characters is missing a name or summary."),
            actions: [TextButton(child: Padding(padding: const EdgeInsets.all(8.0), child: Text("OK")), onPressed: () => Get.back())],
          ));
          return false;
        }
        if (values["settings"].any((v) => v["title"].value.text.isEmpty || v["body"].value.text.isEmpty)) {
          Get.dialog(AlertDialog(
            title: Text("Setting details missing"),
            content: Text("One of your PR's settings is missing a title or summary."),
            actions: [TextButton(child: Padding(padding: const EdgeInsets.all(8.0), child: Text("OK")), onPressed: () => Get.back())],
          ));
          return false;
        }
        if (values["history"].any((v) => v["title"].value.text.isEmpty || v["body"].value.text.isEmpty)) {
          Get.dialog(AlertDialog(
            title: Text("Historical event details missing"),
            content: Text("One of your PR's historical events is missing a title or summary."),
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
        Future.sync(() async {
          final extraFile = File(platformStorageDir.absolute.path + "/lldj-realms/" + _id + ".json");
          var _condition = (values["characters"].isEmpty && values["settings"].isEmpty && values["history"].isEmpty);
          if (!_condition) await extraFile.writeAsString(jsonEncode({
            "characters": values["characters"].map<Map<String, String>>((e) => {
              "body": e["body"].value.text as String,
              "title": e["title"].value.text as String
            }).toList(),
            "settings": values["settings"].map<Map<String, String?>>((e) => {
              "body": e["body"].value.text as String,
              "title": e["title"].value.text as String
            }).toList(),
            "history": values["history"].map<Map<String, String?>>((e) => {
              "body": e["body"].value.text as String,
              "title": e["title"].value.text as String
            }).toList(),
          }));
          else if (_condition && await extraFile.exists()) {
            extraFile.delete();
          }
        });
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