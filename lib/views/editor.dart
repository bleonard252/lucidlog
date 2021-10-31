import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:journal/db/dream.dart';
import 'package:journal/main.dart';
import 'package:journal/views/optional_features.dart';
import 'package:objectdb/objectdb.dart';
import 'package:date_field/date_field.dart';

class DreamEdit extends StatefulWidget {
  final DreamRecord? dream;
  final DreamEditMode mode;
  DreamEdit({
    Key? key,
    this.dream,
    required this.mode
  }) : super(key: key);

  @override
  _DreamEditState createState() => _DreamEditState();
}

class _DreamEditState extends State<DreamEdit> {
  late final TextEditingController titleController;
  late final TextEditingController summaryController;
  late final TextEditingController tagController;
  bool isDreamLucid = false;
  bool _isDreamInRealm = false;
  bool isDreamCanonToRealm = true;
  //bool isDreamWild = false;
  bool isDreamForgotten = false;
  List<String> tags = [];
  List<String> methods = [];
  List<Map<String, dynamic>> plot = [];
  DateTime dateValue = DateTime.now();
  bool isPlotlinesEnabled = false;
  String selectedRealmId = "";

  @override
  void initState() {
    titleController = TextEditingController(text: widget.dream?.title ?? "");
    summaryController = TextEditingController(text: widget.dream?.body ?? "");
    tagController = TextEditingController(text: "");
    isDreamLucid = widget.dream?.lucid ?? isDreamLucid;
    //isDreamWild = widget.dream?.wild ?? isDreamWild;
    isDreamForgotten = widget.dream?.forgotten ?? isDreamForgotten;
    dateValue = widget.dream?.timestamp ?? dateValue;
    tags = widget.dream?.tags ?? [];
    methods = widget.dream?.methods ?? [];
    if (widget.dream?.id != null) File(platformStorageDir.absolute.path + "/lldj-plotlines/" + widget.dream!.id + ".json").readAsString().then((value) {
      plot = jsonDecode(value);
    });
    isPlotlinesEnabled = plot.isNotEmpty || widget.mode == DreamEditMode.edit;
    selectedRealmId = widget.dream?.realm ?? "";
    _isDreamInRealm = selectedRealmId != "";
    isDreamCanonToRealm = widget.dream?.realmCanon ?? true;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      globalBackgroundColor: Get.theme.canvasColor,
      dotsDecorator: DotsDecorator(activeColor: Get.theme.primaryColor),
      color: Get.theme.primaryColor,
      pages: [
        if (widget.mode == DreamEditMode.tag || widget.mode == DreamEditMode.complete) PageViewModel(
          title: widget.mode == DreamEditMode.tag ? "Tag your dream!" : "Review your tags",
          bodyWidget: SingleChildScrollView(child: Column(
            children: [
              if (widget.mode == DreamEditMode.complete) Container(
                alignment: Alignment.topLeft, 
                child: IconButton(onPressed: Get.back, icon: Icon(Icons.arrow_back))
              ),
              Wrap(
                alignment: WrapAlignment.start,
                direction: Axis.horizontal,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: [
                for (var tag in tags) Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Chip(
                    label: Text(tag),
                    onDeleted: widget.mode == DreamEditMode.tag ? () {
                      tags.remove(tag);
                      setState(() {});
                    } : null,
                  )
                ),
                if (widget.mode == DreamEditMode.tag) TextField(
                  controller: tagController,
                  decoration: InputDecoration(
                    hintText: "Add a new tag with comma (,) or Enter"
                  ),
                  onChanged: (v) {
                    if (v.endsWith(",")) {
                      if (v.replaceFirst(",", "") != "") tags.add(v.replaceFirst(",", ""));
                      tagController.clear();
                      setState(() {});
                    }
                  },
                  onEditingComplete: () {
                    if (tagController.value.text.isNotEmpty) tags.add(tagController.value.text.replaceFirst(",", ""));
                    tagController.clear();
                    setState(() {});
                  },
                )
              ]) 
            ],
          )),
        ),
        if (widget.mode != DreamEditMode.tag || widget.mode == DreamEditMode.complete) PageViewModel(
          title: widget.mode == DreamEditMode.create || widget.mode == DreamEditMode.complete ? "Record your dream!"
          : "",
          bodyWidget: SingleChildScrollView(
            child: Column(
              children: [
                Row(children: [
                  if (widget.mode != DreamEditMode.complete) IconButton(onPressed: Get.back, icon: Icon(Icons.arrow_back)),
                  Expanded(child: Container()),
                  if (widget.mode == DreamEditMode.complete || widget.mode == DreamEditMode.edit)
                    TextButton.icon(
                      onPressed: () async {
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
                        await widget.dream?.delete();
                        Get.offAllNamed("/");
                      },
                      icon: Icon(Icons.delete_outline),
                      label: Text("Delete"),
                      style: ButtonStyle(
                        foregroundColor: _Red(),
                        overlayColor: MaterialStateProperty.all(Colors.red.withAlpha(40)),
                        padding: MaterialStateProperty.all(EdgeInsets.all(24.0))
                      ),
                    ),
                ]),
                TextField(
                  controller: titleController, 
                  decoration: InputDecoration(
                    labelText: "Title",
                    hintText: "Titles help you distinguish dreams.",
                  ),
                  keyboardAppearance: Brightness.dark,
                  keyboardType: TextInputType.text,
                ),
                DateTimeField(
                  onDateSelected: (value) {dateValue = value; setState(() {});}, 
                  selectedDate: dateValue,
                  mode: DateTimeFieldPickerMode.dateAndTime,
                  decoration: InputDecoration(
                    labelText: "Date and time"
                  ),
                ),
                TextField(
                  controller: summaryController, 
                  decoration: InputDecoration(
                    alignLabelWithHint: true,
                    labelText: "Summary",
                    hintText: "Write more about a dream!"
                  ),
                  keyboardAppearance: Brightness.dark,
                  keyboardType: TextInputType.multiline,
                  minLines: 5,
                  maxLines: null,
                ),
                if (OptionalFeatures.plotlines != PlotlineTypes.NONE && !isPlotlinesEnabled) Row(children: [
                  Expanded(child: Container()),
                  TextButton(
                    onPressed: () {setState(() {isPlotlinesEnabled = true;});},
                    //icon: Icon(Icons.delete_outline),
                    child: Text("Enable Plotlines"),
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all(EdgeInsets.all(24.0))
                    ),
                  ),
                ]),
              ],
            ),
          )
        ),
        PageViewModel(
          title: "",
          bodyWidget: Column(children: [
            if (widget.mode != DreamEditMode.tag) SwitchListTile(
              title: Text("Do you have insufficient recall for this dream?"),
              subtitle: Text("If you did not have any dreams, or have forgotten them, use this to keep the habit of logging alive."),
              value: isDreamForgotten,
              onChanged: (newValue) => setState(() => isDreamForgotten = newValue)
            ),
            SwitchListTile(
              title: Text("Was this dream lucid?"),
              subtitle: Text("Were you aware you were dreaming? If you don't know, don't touch this."),
              value: isDreamLucid, 
              onChanged: (newValue) => setState(() => isDreamLucid = newValue)
            ),
            if (isDreamLucid && OptionalFeatures.wildDistinction && !OptionalFeatures.rememberMethods) SwitchListTile(
              title: Text("Was this lucid dream wake-induced?"),
              value: methods.contains("WILD"),
              onChanged: (newValue) => setState(() => newValue ? methods.add("WILD") : methods.remove("WILD"))
            ),
            if (OptionalFeatures.realms) SwitchListTile(
              title: Text("Was this dream in a persistent realm?"),
              subtitle: Text("Did this dream take place in a persistent realm, whether you consider it part of the plot."),
              value: _isDreamInRealm, 
              onChanged: (newValue) => setState(() => _isDreamInRealm = newValue)
            ),
            if (_isDreamInRealm) SwitchListTile(
              title: Text("Do you consider this dream canon?"),
              subtitle: Text("Is this dream part of the plot for the PR?"),
              value: isDreamCanonToRealm,
              onChanged: (newValue) => setState(() => isDreamCanonToRealm = newValue)
            ),
          ])
        ),
        if (_isDreamInRealm) PageViewModel(
          title: "Select the persistent realm",
          bodyWidget: StatefulBuilder(
            builder: (context, setState) {
              return ListView.builder(
                shrinkWrap: true,
                itemBuilder: (_, i) => realmList[i].title == "" ? Container() : ListTile(
                  selected: selectedRealmId == realmList[i].id,
                  title: Text(realmList[i].title),
                  onTap: () => setState(() => selectedRealmId = realmList[i].id),
                ),
                itemCount: realmList.length,
              );
            }
          )
        ),
        if (isDreamLucid && widget.mode != DreamEditMode.tag && OptionalFeatures.rememberMethods) PageViewModel(
          title: "Methods used",
          bodyWidget: Column(
            children: [
              if (OptionalFeatures.wildDistinction) CheckboxListTile(
                activeColor: Colors.amber,
                checkColor: Get.theme.canvasColor,
                value: methods.contains("WILD"), 
                onChanged: (x) => setState(() => x ?? false 
                ? methods.add("WILD")
                : methods.remove("WILD")),
                title: Text("WILD", style: TextStyle(color: Colors.amber)),
              ),
              for (var i in [...sharedPreferences.getStringList("ld-methods") ?? [], ...methods].toSet())
              if ((OptionalFeatures.wildDistinction && i != "WILD") || !OptionalFeatures.wildDistinction) CheckboxListTile(
                activeColor: Get.theme.primaryColor,
                checkColor: Get.theme.canvasColor,
                value: methods.contains(i), 
                onChanged: (x) => setState(() => x ?? false 
                ? methods.add(i)
                : methods.remove(i)),
                title: Text(i, style: TextStyle(
                  // Gray out techniques that have been removed from the list
                  color: Colors.white.withAlpha(sharedPreferences.getStringList("ld-methods")?.contains(i)??false ? 255 : 127))
                ),
              )
            ],
          )
        ),
        if (OptionalFeatures.plotlines != PlotlineTypes.NONE && isPlotlinesEnabled) PageViewModel(
          title: "Plot points",
          bodyWidget: ReorderableListView(shrinkWrap: true, children: [
            for (var event in plot) Builder(
              key: ValueKey(event),
              builder: (context) {
                final _titleController = event["tc"] ?? TextEditingController(text: event["subtitle"] ?? "");
                plot[plot.indexOf(event)]["tc"] = _titleController;
                final _bodyController = event["bc"] ?? TextEditingController(text: event["body"] ?? "No body! Whoops");
                plot[plot.indexOf(event)]["bc"] = _bodyController;
                return Column(children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          onChanged: (newValue) {
                            final index = plot.indexOf(event);
                            plot[index]["subtitle"] = newValue;
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            labelText: "Subtitle",
                            hintText: "Subtitles help you identify scenes or events.",
                          ),
                          keyboardAppearance: Brightness.dark,
                          keyboardType: TextInputType.text,
                        ),
                      ),
                      Tooltip(
                        message: "Remove",
                        child: IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => setState(() => plot.remove(event)),
                        ),
                      )
                    ],
                  ),
                  TextField(
                    controller: _bodyController,
                    onChanged: (newValue) {
                      final index = plot.indexOf(event);
                      plot[index]["body"] = newValue;
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      alignLabelWithHint: true,
                      labelText: "Summary",
                      hintText: "Write more about a scene or event!"
                    ),
                    keyboardAppearance: Brightness.dark,
                    keyboardType: TextInputType.multiline,
                    minLines: 5,
                    maxLines: null,
                  ),
                  Divider()
                ]);
              }
            )
          ], onReorder: (oldPos, newPos) {
            final oldItem = plot.removeAt(oldPos);
            plot.insert(newPos, oldItem);
            setState(() {});
          }),
          footer: TextButton(onPressed: () => setState(() => plot.add({"body": "New body text"})), child: Text("New plot point"))
        ),
      ],
      next: Text("Next"),
      done: Text(widget.mode == DreamEditMode.create || widget.mode == DreamEditMode.tag ? "Create" 
      : widget.mode == DreamEditMode.complete ? "Complete"
      : "Update"),
      onChange: (page) {
        if (tagController.value.text.isNotEmpty) tags.add(tagController.value.text.replaceFirst(",", ""));
        tagController.clear();
        setState(() {});
      },
      onDone: () async {
        // == CHECK
        if (!isDreamForgotten && titleController.value.text.isEmpty && summaryController.value.text.isEmpty) return await Get.dialog(AlertDialog(
          title: Text("Content missing"),
          content: Text("How do you expect to remember a dream with nothing written down for it?"),
          actions: [TextButton(child: Padding(padding: const EdgeInsets.all(8.0), child: Text("OK")), onPressed: () => Get.back())],
        ));
        if (!isDreamForgotten && summaryController.value.text.isEmpty) return await Get.dialog(AlertDialog(
          title: Text("Summary missing"),
          content: Text("You need to have some contents for dreams you remember."),
          actions: [TextButton(child: Padding(padding: const EdgeInsets.all(8.0), child: Text("OK")), onPressed: () => Get.back())],
        ));
        if (_isDreamInRealm && selectedRealmId.isEmpty) return await Get.dialog(AlertDialog(
          title: Text("PR selection missing"),
          content: Text("If this dream is part of a PR, you need to specify which PR it is in."),
          actions: [TextButton(child: Padding(padding: const EdgeInsets.all(8.0), child: Text("OK")), onPressed: () => Get.back())],
        ));
        
        // == SAVE
        var newData = {
          "_id": widget.dream?.id ?? ObjectId().hexString,
          "title": titleController.value.text,
          "body": summaryController.value.text,
          "timestamp": dateValue.millisecondsSinceEpoch,
          "lucid": isDreamLucid,
          //"wild": isDreamWild,
          "forgotten": isDreamForgotten,
          "tags": tags,
          "methods": isDreamLucid ? methods : [],
          "incomplete": (widget.mode == DreamEditMode.tag),
          "realm": _isDreamInRealm ? selectedRealmId : null,
          "realm_canon": _isDreamInRealm && selectedRealmId.isNotEmpty ? isDreamCanonToRealm == true : null
        };
        final plotFile = File(platformStorageDir.absolute.path + "/lldj-plotlines/" + (newData["_id"] as String) + ".json");
        if (OptionalFeatures.plotlines != PlotlineTypes.NONE && isPlotlinesEnabled) {
          if (plot != []) await plotFile.writeAsString(jsonEncode(plot.map<Map<String, String?>>((e) => {
            "body": e["body"],
            "subtitle": e["subtitle"]
          }).toList()));
          else if (plot == [] && await plotFile.exists()) {
            plotFile.delete();
          }
        }
        if (widget.mode == DreamEditMode.create || widget.mode == DreamEditMode.tag) {
          database.add(newData);
        } else {
          database[database.indexWhere((element) => element["_id"] == widget.dream!.id)] = newData;
        }
        Get.offAllNamed("/");
      },
    );
  }
}

enum DreamEditMode {
  create,
  edit,
  tag,
  complete
}

class _Red extends MaterialStateColor {
  static Color _defaultColor = Colors.red;
  static Color _pressedColor = Colors.red[700]!;

  const _Red() : super(0xfff44336);

  @override
  Color resolve(Set<MaterialState> states) {
    if (states.contains(MaterialState.pressed)) {
      return _pressedColor;
    }
    return _defaultColor;
  }
}
