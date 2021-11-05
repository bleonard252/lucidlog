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

import '../main.dart';

class DreamEditor extends StatelessWidget {
  final DreamEditMode mode;
  final DreamRecord? dream;
  const DreamEditor({ Key? key, this.mode = DreamEditMode.create, this.dream }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var _dateFormat = sharedPreferences.containsKey("datetime-format")
      ? sharedPreferences.getString("datetime-format") : DateTimeFormats.commonLogFormat;
    return BaseEditor(
      initValues: () => {
        "title": TextEditingController(text: dream?.title ?? ""),
        "body": TextEditingController(text: dream?.body ?? ""),
        "timestamp": dream?.timestamp ?? DateTime.now(),
        "lucid": dream?.lucid ?? false,
        "forgotten": dream?.forgotten ?? false,
        "tags": dream?.tags ?? [],
        "methods": dream?.methods ?? [],
        "_isDreamInRealm": (dream?.realm?.isNotEmpty ?? false) ? true : false,
        "realm": dream?.realm,
        "realm_canon": dream?.realmCanon
      },
      onSave: (values) async {
        // == CHECK
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
          if (values["plot"] != []) await plotFile.writeAsString(jsonEncode(values["plot"].map<Map<String, String?>>((e) => {
            "body": e["body"],
            "subtitle": e["subtitle"]
          }).toList()));
          else if (values["plot"] == [] && await plotFile.exists()) {
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
      leftSide: (context) => [
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: ListTile(
            title: Text("Title"),
            subtitle: TextField(
              controller: BaseEditor.of(context)?.values["title"],
              decoration: InputDecoration(
                //labelText: "Title",
                hintText: "Titles help you distinguish dreams.",
                //contentPadding: EdgeInsets.zero
                //isCollapsed: true,
                isDense: true
              ),
              keyboardAppearance: Brightness.dark,
              keyboardType: TextInputType.text,
              maxLines: 1
            ),
          ),
        ),
        ListTile(
          title: Text("Date and Time"),
          // onDateSelected: (value) {dateValue = value; setState(() {});}, 
          // selectedDate: dateValue,
          // mode: DateTimeFieldPickerMode.dateAndTime,
          // decoration: InputDecoration(
          //   labelText: "Date and time"
          // ),
          trailing: Icon(Mdi.calendarEdit),
          subtitle: Text((BaseEditor.of(context)?.values["timestamp"] as DateTime).format(_dateFormat ?? DateTimeFormats.commonLogFormat)),
          onTap: () async {
            var date = await showDatePicker(
              context: context,
              initialDate: BaseEditor.of(context)?.values["timestamp"],
              firstDate: DateTime.fromMillisecondsSinceEpoch(0),
              lastDate: DateTime(3000)
            );
            if (date == null) return;
            var time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(BaseEditor.of(context)?.values["timestamp"]),
            );
            if (time == null) return;
            BaseEditor.of(context)?.setValue("timestamp", date.add(Duration(hours: time.hour, minutes: time.minute)));
          },
        ),
        EditorRightPaneButton(ListTile(
          title: Text("Body"),
        ), "body"),
        EditorToggleButton(
          valueKey: "lucid",
          title: Text("Lucid Dream"),
          subtitle: Text("You were aware that you were dreaming."),
        )
      ],
      leftSideTitle: Text("Journal a Dream"),
      rightSide: (context, pageName) {
        if (pageName == "body") return Container(
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.topLeft,
          child: TextField(
            controller: BaseEditor.of(context)?.values["body"], 
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
        );
      },
      rightSideTitle: (pageName) {
        if (pageName == "body") return Text("Body");
      }
    );
  }
}