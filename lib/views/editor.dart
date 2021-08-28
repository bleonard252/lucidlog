import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:journal/db/dream.dart';
import 'package:journal/main.dart';
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
  bool isDreamLucid = false;
  bool isDreamWild = false;
  bool isDreamForgotten = false;
  DateTime dateValue = DateTime.now();

  @override
  void initState() {
    titleController = TextEditingController(text: widget.dream?.title ?? "");
    summaryController = TextEditingController(text: widget.dream?.body ?? "");
    isDreamLucid = widget.dream?.lucid ?? isDreamLucid;
    isDreamWild = widget.dream?.wild ?? isDreamWild;
    isDreamForgotten = widget.dream?.forgotten ?? isDreamForgotten;
    dateValue = widget.dream?.timestamp ?? dateValue;
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
          title: widget.mode == DreamEditMode.create ? "Record your dream!"
          : widget.mode == DreamEditMode.complete ? "Review this information"
          : "",
          bodyWidget: SingleChildScrollView(
            child: Column(
              children: [
                Row(children: [
                  IconButton(onPressed: Get.back, icon: Icon(Icons.arrow_back)),
                  Expanded(child: Container()),
                  if (widget.mode == DreamEditMode.complete || widget.mode == DreamEditMode.edit)
                    TextButton.icon(
                      onPressed: () async {
                        var _do = await Get.dialog(AlertDialog(
                          title: Text("Are you sure?"),
                          content: Text("Are you sure you want to delete this journal entry?"),
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
                    labelText: "Summary, plot, or body",
                    hintText: "Write more about a dream!"
                  ),
                  keyboardAppearance: Brightness.dark,
                  keyboardType: TextInputType.multiline,
                  minLines: 5,
                  maxLines: null,
                )
              ],
            ),
          )
        ),
        PageViewModel(
          title: "",
          bodyWidget: Column(children: [
            SwitchListTile(
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
            if (isDreamLucid) SwitchListTile(
              title: Text("Was this lucid dream wake-induced?"),
              value: isDreamWild,
              onChanged: (newValue) => setState(() => isDreamWild = newValue)
            ),
          ])
        ),
        if (isDreamLucid) PageViewModel(
          title: "Methods used",
          bodyWidget: Column(
            children: [
              for (var i in sharedPreferences.getStringList("ld-methods") ?? [])
              CheckboxListTile(
                value: widget.dream?.methods.contains(i) ?? false, 
                onChanged: (x) => x ?? false 
                ? widget.dream?.methods.add(i)
                : widget.dream?.methods.remove(i),
                title: Text(i),
              )
            ],
          )
        ),
      ],
      next: Text("Next"),
      done: Text(widget.mode == DreamEditMode.create ? "Create" : "Update"),
      onDone: () async {
        var newData = {
          "title": titleController.value.text,
          "body": summaryController.value.text,
          "timestamp": dateValue.millisecondsSinceEpoch,
          "lucid": isDreamLucid,
          "wild": isDreamWild,
          "forgotten": isDreamForgotten,
        };
        if (widget.mode == DreamEditMode.create) database.insert(newData);
        else await database.update({"_id": widget.dream!.id}, newData);
        Get.offAllNamed("/");
      },
    );
  }
}

enum DreamEditMode {
  create,
  edit,
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
