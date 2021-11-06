//import 'package:date_field/date_field.dart';
import 'dart:convert';
import 'dart:io';

import 'package:date_time_format/date_time_format.dart';
import "package:flutter/material.dart";
import 'package:get/get.dart';
import 'package:journal/db/dream.dart';
import 'package:journal/views/editor.dart';
import 'package:journal/views/optional_features.dart';
import 'package:journal/widgets/editor.dart';
import 'package:date_time_format/date_time_format.dart';
import 'package:mdi/mdi.dart';
import 'package:objectdb/objectdb.dart';
import 'package:simple_markdown_editor/simple_markdown_editor.dart';

import '../main.dart';

class DreamEditor extends StatelessWidget {
  final DreamEditMode mode;
  final DreamRecord? dream;
  DreamEditor({ Key? key, this.mode = DreamEditMode.create, this.dream }) : super(key: key);

  final TextEditingController tagController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var _dateFormat = sharedPreferences.containsKey("datetime-format")
      ? sharedPreferences.getString("datetime-format") : DateTimeFormats.commonLogFormat;
    return BaseEditor(
      defaultPage: 
      mode == DreamEditMode.tag || mode == DreamEditMode.complete ? "tags"
      : mode == DreamEditMode.edit ? null
      : "body",
      initValues: () => {
        "title": TextEditingController(text: dream?.title ?? ""),
        "body": TextEditingController(text: dream?.body ?? ""),
        "timestamp": dream?.timestamp ?? DateTime.now(),
        "lucid": dream?.lucid ?? false,
        "wild": dream?.wild ?? false,
        "forgotten": dream?.forgotten ?? false,
        "tags": dream?.tags ?? [],
        "methods": dream?.methods ?? [],
        "_isDreamInRealm": (dream?.realm?.isNotEmpty ?? false) ? true : false,
        "_hasCompletedInitialFlow": (mode == DreamEditMode.edit),
        "realm": dream?.realm,
        "realm_canon": dream?.realmCanon ?? true,
        "plot": dream?.plotFile.existsSync() ?? false ? jsonDecode(dream!.plotFile.readAsStringSync()).map((v) => {
          "subtitle": TextEditingController(text: v["subtitle"]),
          "body": TextEditingController(text: v["body"]),
        }).toList() : []
      },
      onSave: (values) async {
        // == CHECK
        if (mode != DreamEditMode.tag) {
          if (!values["forgotten"] && values["title"].value.text.isEmpty && values["body"].value.text.isEmpty) {
            await Get.dialog(AlertDialog(
              title: Text("Content missing"),
              content: Text("How do you expect to remember a dream with nothing written down for it?"),
              actions: [TextButton(child: Padding(padding: const EdgeInsets.all(8.0), child: Text("OK")), onPressed: () => Get.back())],
            ));
            return false;
          }
          if (!values["forgotten"] && values["body"].value.text.isEmpty) {
            await Get.dialog(AlertDialog(
              title: Text("Summary missing"),
              content: Text("You need to have some contents for dreams you remember."),
              actions: [TextButton(child: Padding(padding: const EdgeInsets.all(8.0), child: Text("OK")), onPressed: () => Get.back())],
            ));
            return false;
          }
          if (values["_isDreamInRealm"] && values["realm"].isEmpty) {
              await Get.dialog(AlertDialog(
              title: Text("PR selection missing"),
              content: Text("If this dream is part of a PR, you need to specify which PR it is in."),
              actions: [TextButton(child: Padding(padding: const EdgeInsets.all(8.0), child: Text("OK")), onPressed: () => Get.back())],
            ));
            return false;
          }
        }
        // == SAVE
        var newData = {
          "_id": dream?.id ?? ObjectId().hexString,
          "title": values["title"].value.text,
          "body": values["body"].value.text,
          "timestamp": values["timestamp"].millisecondsSinceEpoch,
          "lucid": values["lucid"],
          "forgotten": values["forgotten"],
          "tags": values["tags"],
          "methods": values["lucid"] ? values["methods"] : [],
          "incomplete": (mode == DreamEditMode.tag),
          "realm": values["_isDreamInRealm"] ? values["realm"] : null,
          "realm_canon": values["_isDreamInRealm"] && values["realm"].isNotEmpty ? values["realm_canon"] == true : null
        };
        final plotFile = File(platformStorageDir.absolute.path + "/lldj-plotlines/" + (newData["_id"] as String) + ".json");
        if (OptionalFeatures.plotlines != PlotlineTypes.NONE) {
          if (values["plot"].isNotEmpty) await plotFile.writeAsString(jsonEncode(values["plot"].map<Map<String, String?>>((e) => {
            "body": e["body"].value.text as String?,
            "subtitle": e["subtitle"].value.text as String?,
          }).toList()));
          else if (values["plot"].isEmpty && await plotFile.exists()) {
            plotFile.delete();
          }
        }
        if (mode == DreamEditMode.create || mode == DreamEditMode.tag) {
          database.add(newData);
        } else {
          database[database.indexWhere((element) => element["_id"] == dream!.id)] = newData;
        }
        Get.offAllNamed("/");
        return false;
      },
      leftSide: (context) {final editor = BaseEditor.of(context)!; return [
        if ((mode == DreamEditMode.tag || mode == DreamEditMode.complete)) EditorRightPaneButton(ListTile(
          title: mode == DreamEditMode.tag ? Text("Add tags") : Text("Review tags"),
          subtitle: Text((editor.values["tags"].length ?? 0).toString()
          + " tag${(editor.values["tags"].length ?? 0) == 1 ? "" : "s"}"),
        ), "tags"),
        if (mode != DreamEditMode.tag) EditorRightPaneButton(ListTile(
          title: Text("Body"),
          subtitle: editor.values["title"].value.text.isNotEmpty
          ? Text(editor.values["title"].value.text) : Text("No title given yet"),
        ), "body"),
        if (mode == DreamEditMode.edit || mode == DreamEditMode.complete) ListTile(
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
            await dream?.delete();
            Get.offAllNamed("/");
          },
        ),
        ListTile(
          title: Text("Date and Time"),
          trailing: Icon(Mdi.calendarEdit),
          subtitle: Text((editor.values["timestamp"] as DateTime).format(_dateFormat ?? DateTimeFormats.commonLogFormat)),
          onTap: () async {
            var date = await showDatePicker(
              context: context,
              initialDate: editor.values["timestamp"],
              firstDate: DateTime.fromMillisecondsSinceEpoch(0),
              lastDate: DateTime(3000)
            );
            if (date == null) return;
            var time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(editor.values["timestamp"]),
            );
            if (time == null) return;
            editor.setValue("timestamp", date.add(Duration(hours: time.hour, minutes: time.minute)));
          },
        ),
        EditorToggleButton(
          valueKey: "forgotten",
          title: Text("Insufficient Recall"),
          subtitle: Text("You forgot or nearly forgot the dream."),
        ),
        EditorToggleButton(
          valueKey: "lucid",
          title: Text("Lucid Dream"),
          subtitle: Text("You were aware that you were dreaming."),
        ),
        if (OptionalFeatures.wildDistinction && !OptionalFeatures.rememberMethods) EditorToggleButton(
          valueKey: "wild",
          title: Text("Wake-initiated"),
          subtitle: Text("You used WILD, SSILD, or a similar technique and became lucid from it."),
          enabled: editor.values["lucid"] ?? false
        ) else if (OptionalFeatures.rememberMethods && mode != DreamEditMode.tag) EditorRightPaneButton(ListTile(
          title: Text("Techniques used"),
          subtitle: Text((editor.values["methods"].length ?? 0).toString()
          + " technique${(editor.values["methods"].length ?? 0) == 1 ? "" : "s"} used" 
          + (DreamRecord.isWild(editor.values["methods"] ?? []) ? "; Wake-initiated" : ""))
        ), "methods"),
        if (OptionalFeatures.realms && mode != DreamEditMode.tag) ...[
          Padding(
          // Used this as a sample header, comment it out until it's needed
          padding: const EdgeInsets.all(8.0).copyWith(top: 24.0),
          child: Row(
            children: [
              Text(
                "PERSISTENT REALM", // Protip: use Dismissable widgets for these items!
                style: TextStyle(color: Get.theme.primaryColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
          EditorToggleButton(
            valueKey: "_isDreamInRealm",
            title: Text("In persistent realm"),
          ),
          EditorToggleButton(
            title: Text("Canon to persistent realm"),
            subtitle: Text("Turn this off if the dream took place in the PR world, but you didn't want it to."),
            valueKey: "realm_canon",
            enabled: editor.values["_isDreamInRealm"] ?? false,
          ),
          EditorRightPaneButton(ListTile(
            title: Text("Choose the PR"),
            subtitle: editor.values["realm"]?.isNotEmpty == true ? 
            Text(realmList.firstWhere((element) => element.id == editor.values["realm"]).title) : Text("No PR chosen"),
            enabled: editor.values["_isDreamInRealm"] ?? false,
          ),
          "realm"),
        ],
        if (OptionalFeatures.plotlines != PlotlineTypes.NONE && mode != DreamEditMode.tag) ...[
          Padding(
            padding: const EdgeInsets.all(8.0).copyWith(top: 24.0),
            child: Row(
              children: [
                Text(
                  "PLOTLINES", // Protip: use Dismissable widgets for these items!
                  style: TextStyle(color: Get.theme.primaryColor, fontWeight: FontWeight.bold),
                ),
                Expanded(child: Container()),
                IconButton(
                  onPressed: () => editor.setValue("plot",
                    (editor.values["plot"] as List)
                    ..add({
                      "body": TextEditingController(),
                      "subtitle": TextEditingController()
                    })
                  ),
                  icon: Icon(Icons.add),
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tightForFinite(height: 24),
                )
              ],
            ),
          ),
          for (var event in editor.values["plot"]) Dismissible(
            key: ObjectKey(event), 
            child: EditorRightPaneButton(ListTile(
              title: event["subtitle"].value.text.isNotEmpty
              ? Text(event["subtitle"].value.text)
              : Text("Scene "+((editor.values["plot"].indexOf(event)+1).toString())),
              subtitle: event["body"].value.text.isNotEmpty
              ? Text(event["body"].value.text, maxLines: 1, overflow: TextOverflow.ellipsis)
              : Text("No summary given"),
            ), "plot:"+(editor.values["plot"].indexOf(event).toString())),
            background: Container(color:Colors.red, child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.delete),
            ), alignment: Alignment.centerLeft),
            secondaryBackground: Container(color:Colors.red, child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.delete),
            ), alignment: Alignment.centerRight),
            onDismissed: (_) => editor.setValue("plot", editor.values["plot"]..remove(event)),
          )
        ]
      ];},
      leftSideTitle: Text("Journal a Dream"),
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
              if (mode != DreamEditMode.edit && !editor.values["_hasCompletedInitialFlow"]) SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: OutlinedButton(
                    onPressed: () {
                      editor.setValue("_hasCompletedInitialFlow", true);
                      editor.setActivePage(null);
                    },
                    child: Text("Continue")
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
        if (pageName == "tags") return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // if (mode == DreamEditMode.complete) Container(
              //   alignment: Alignment.topLeft, 
              //   child: IconButton(onPressed: Get.back, icon: Icon(Icons.arrow_back))
              // ),
              Wrap(
                alignment: WrapAlignment.start,
                direction: Axis.horizontal,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: [
                for (var tag in editor.values["tags"]) Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Chip(
                    label: Text(tag),
                    onDeleted: mode == DreamEditMode.tag ? () {
                      editor.setValue("tags", editor.values["tags"]..remove(tag));
                    } : null,
                  )
                ),
                if (mode == DreamEditMode.tag) TextField(
                  controller: tagController,
                  decoration: InputDecoration(
                    hintText: "Add a new tag with comma (,) or Enter"
                  ),
                  onChanged: (v) {
                    if (v.endsWith(",")) {
                      if (v.replaceFirst(",", "") != "") 
                      editor.setValue("tags", editor.values["tags"]..add(v.replaceFirst(",", "")));
                      tagController.clear();
                    }
                  },
                  onEditingComplete: () {
                    if (tagController.value.text.isNotEmpty) editor.setValue("tags", editor.values["tags"]..add(tagController.value.text.replaceFirst(",", "")));
                    tagController.clear();
                  },
                )
              ]),
              Expanded(child: Container()),
              if (mode == DreamEditMode.complete && !editor.values["_hasCompletedInitialFlow"]) Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: OutlinedButton(
                        onPressed: () {
                          //editor.setValue("_hasCompletedInitialFlow", true);
                          editor.setActivePage("body");
                        },
                        child: Text("Next")
                      ),
                    ),
                  ),
                ],
              ) else if (mode == DreamEditMode.tag && !editor.values["_hasCompletedInitialFlow"]) Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: OutlinedButton(
                        onPressed: () {
                          editor.setValue("_hasCompletedInitialFlow", true);
                          //editor.setActivePage("body");
                        },
                        child: Text("Continue")
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: OutlinedButton(
                        onPressed: () {
                          //editor.setValue("_hasCompletedInitialFlow", true);
                          //editor.setActivePage("body");
                          editor.forceSave();
                        },
                        child: Text("Finish")
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
        if (pageName == "realm") return Builder(
          builder: (context) {
            final _state = BaseEditor.of(context)!;
            final _value = _state.values["realm"];
            return ListView.builder(
              shrinkWrap: true,
              itemBuilder: (_, i) => realmList[i].title == "" ? Container() : ListTile(
                selected: _value == realmList[i].id,
                title: Text(realmList[i].title),
                onTap: () => _state.setValue("realm", realmList[i].id),
              ),
              itemCount: realmList.length,
            );
          }
        );
        if (pageName == "methods") return Builder(
          builder: (context) {
            final _state = BaseEditor.of(context)!;
            List methods = _state.values["methods"];
            return ListView(
              children: [
                if (OptionalFeatures.wildDistinction) CheckboxListTile(
                  activeColor: Colors.amber,
                  checkColor: Get.theme.canvasColor,
                  value: methods.contains("WILD"), 
                  onChanged: (x) => _state.setValue("methods", x ?? false 
                  ? (methods..add("WILD"))
                  : (methods..remove("WILD"))),
                  title: Text("WILD", style: TextStyle(color: Colors.amber)),
                ),
                for (var i in [...sharedPreferences.getStringList("ld-methods") ?? [], ...methods].toSet())
                if ((OptionalFeatures.wildDistinction && i != "WILD") || !OptionalFeatures.wildDistinction) CheckboxListTile(
                  activeColor: Get.theme.primaryColor,
                  checkColor: Get.theme.canvasColor,
                  value: methods.contains(i), 
                  onChanged: (x) => _state.setValue("methods", x ?? false 
                  ? (methods..add(i))
                  : (methods..remove(i))),
                  title: Text(i, style: TextStyle(
                    // Gray out techniques that have been removed from the list
                    color: Colors.white.withAlpha(sharedPreferences.getStringList("ld-methods")?.contains(i)??false ? 255 : 127))
                  ),
                )
              ],
            );
          }
        );
        if (pageName.startsWith("plot:")) {
          final i = int.parse(pageName.replaceFirst("plot:",""));
          if (i >= editor.values["plot"].length) {
            editor.setActivePage(null, true);
            return null;
          }
          return Container(
            padding: const EdgeInsets.all(8.0),
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextField(
                  controller: editor.values["plot"][i]["subtitle"],
                  decoration: InputDecoration(
                    labelText: "Subtitle",
                    hintText: "Give this plot point a name (optional).",
                  ),
                  keyboardAppearance: Brightness.dark,
                  keyboardType: TextInputType.text,
                  maxLines: 1,
                ),
                Expanded(
                  child: TextField(
                    controller: editor.values["plot"][i]["body"],
                    decoration: InputDecoration(
                      alignLabelWithHint: true,
                      labelText: "Summary",
                      hintText: "Write more about this scene or event!",
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
        if (pageName == "tags" && mode == DreamEditMode.tag) return Text("Tag your dream");
        else if (pageName == "tags") return Text("Review tags");
        if (pageName == "realm") return Text("Select a PR");
        if (pageName == "methods") return Text("Techniques");
        if (pageName.startsWith("plot:")) return Text("Plot point");
      }
    );
  }
}