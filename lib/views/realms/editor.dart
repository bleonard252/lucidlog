import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:journal/db/realm.dart';
import 'package:journal/main.dart';
import 'package:objectdb/objectdb.dart';

class RealmEdit extends StatefulWidget {
  final RealmRecord? realm;
  final RealmEditMode mode;
  RealmEdit({
    Key? key,
    this.realm,
    required this.mode
  }) : super(key: key);

  @override
  _RealmEditState createState() => _RealmEditState();
}

class _RealmEditState extends State<RealmEdit> {
  late final TextEditingController titleController;
  late final TextEditingController summaryController;
  DateTime dateValue = DateTime.now();

  List<String> selectedDreamIds = [];

  @override
  void initState() {
    titleController = TextEditingController(text: widget.realm?.title ?? "");
    summaryController = TextEditingController(text: widget.realm?.body ?? "");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      globalBackgroundColor: Get.theme.canvasColor,
      dotsDecorator: DotsDecorator(activeColor: Get.theme.primaryColor),
      color: Get.theme.primaryColor,
      pages: [
        PageViewModel(
          title: "Record a Persistent Realm",
          bodyWidget: SingleChildScrollView(
            child: Column(
              children: [
                Row(children: [
                  IconButton(onPressed: Get.back, icon: Icon(Icons.arrow_back)),
                  Expanded(child: Container()),
                  if (widget.mode == RealmEditMode.edit)
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
                        database.where((element) => element["realm"] == widget.realm?.id).forEach((element) {
                          final i = database.indexOf(element);
                          database[i]["realm"] = null;
                          database[i]["realm_canon"] = null;
                        });
                        await widget.realm?.delete();
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
                  ),
                  keyboardAppearance: Brightness.dark,
                  keyboardType: TextInputType.text,
                ),
                TextField(
                  controller: summaryController, 
                  decoration: InputDecoration(
                    alignLabelWithHint: true,
                    labelText: "Summary",
                    hintText: "What sets this PR apart?"
                  ),
                  keyboardAppearance: Brightness.dark,
                  keyboardType: TextInputType.multiline,
                  minLines: 5,
                  maxLines: null,
                ),
              ],
            ),
          )
        ),
        // Add character, setting, and history pages
        // if (OptionalFeatures.plotlines != PlotlineTypes.NONE && isPlotlinesEnabled) PageViewModel(
        //   title: "Plot points",
        //   bodyWidget: ReorderableListView(shrinkWrap: true, children: [
        //     for (var event in plot) Builder(
        //       key: ValueKey(event),
        //       builder: (context) {
        //         final _titleController = event["tc"] ?? TextEditingController(text: event["subtitle"] ?? "");
        //         plot[plot.indexOf(event)]["tc"] = _titleController;
        //         final _bodyController = event["bc"] ?? TextEditingController(text: event["body"] ?? "No body! Whoops");
        //         plot[plot.indexOf(event)]["bc"] = _bodyController;
        //         return Column(children: [
        //           TextField(
        //             controller: _titleController,
        //             onChanged: (newValue) {
        //               final index = plot.indexOf(event);
        //               plot[index]["subtitle"] = newValue;
        //               setState(() {});
        //             },
        //             decoration: InputDecoration(
        //               labelText: "Subtitle",
        //               hintText: "Subtitles help you identify scenes or events.",
        //             ),
        //             keyboardAppearance: Brightness.dark,
        //             keyboardType: TextInputType.text,
        //           ),
        //           TextField(
        //             controller: _bodyController,
        //             onChanged: (newValue) {
        //               final index = plot.indexOf(event);
        //               plot[index]["body"] = newValue;
        //               setState(() {});
        //             },
        //             decoration: InputDecoration(
        //               alignLabelWithHint: true,
        //               labelText: "Summary",
        //               hintText: "Write more about a scene or event!"
        //             ),
        //             keyboardAppearance: Brightness.dark,
        //             keyboardType: TextInputType.multiline,
        //             minLines: 5,
        //             maxLines: null,
        //           ),
        //           Divider()
        //         ]);
        //       }
        //     )
        //   ], onReorder: (oldPos, newPos) {
        //     final oldItem = plot.removeAt(oldPos);
        //     plot.insert(newPos, oldItem);
        //     setState(() {});
        //   }),
        //   footer: TextButton(onPressed: () => setState(() => plot.add({"body": "New body text"})), child: Text("New plot point"))
        // ),
        if (dreamList.isNotEmpty && widget.mode == RealmEditMode.create) PageViewModel(
          title: "Add dreams to your PR!",
          bodyWidget: StatefulBuilder(
            builder: (context, setState) {
              return ListView.builder(
                shrinkWrap: true,
                itemBuilder: (_, i) => dreamList[i].title == "" ? Container() : ListTile(
                  selected: selectedDreamIds.contains(dreamList[i].id),
                  title: Text(dreamList[i].title),
                  onTap: () => setState(() => selectedDreamIds.contains(dreamList[i].id) 
                  ? selectedDreamIds.remove(dreamList[i].id)
                  : selectedDreamIds.add(dreamList[i].id)),
                ),
                itemCount: dreamList.length,
              );
            }
          )
        ),
      ],
      next: Text("Next"),
      done: Text(widget.mode == RealmEditMode.create ? "Create" : "Update"),
      // onChange: (page) {
      //   if (tagController.value.text.isNotEmpty) tags.add(tagController.value.text.replaceFirst(",", ""));
      //   tagController.clear();
      //   setState(() {});
      // },
      onDone: () async {
        final _id = widget.realm?.id ?? ObjectId().hexString;
        var newData = {
          "_id": _id,
          "title": titleController.value.text,
          "body": summaryController.value.text,
          //"timestamp": dateValue.millisecondsSinceEpoch,
        };
        for (var id in selectedDreamIds) {
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
        if (widget.mode == RealmEditMode.create) {
          realmDatabase.add(newData);
        } else {
          realmDatabase[realmDatabase.indexWhere((element) => element["_id"] == widget.realm!.id)] = newData;
        }
        Get.back();
      },
    );
  }
}

enum RealmEditMode {
  create,
  edit,
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
