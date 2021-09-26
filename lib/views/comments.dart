
import 'dart:convert';
import 'dart:io';

import 'package:date_time_format/date_time_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:journal/db/comment.dart';
import 'package:journal/db/dream.dart';
import 'package:journal/main.dart';

class DetailsCommentsSection extends StatefulWidget {
  final DreamRecord dream;
  const DetailsCommentsSection({ required this.dream, Key? key }) : super(key: key);

  @override
  _DetailsCommentsSectionState createState() => _DetailsCommentsSectionState();
}

class _DetailsCommentsSectionState extends State<DetailsCommentsSection> {
  final TextEditingController newCommentController = TextEditingController();
  bool _writing = false;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      width: 999999999,
      child: Material(
        elevation: 2,
        type: MaterialType.card,
        color: Get.theme.cardColor,
        borderRadius: BorderRadius.all(Radius.circular(0)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Comments", 
              style: Get.textTheme.subtitle1?.copyWith(fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: TextField(
                  controller: newCommentController,
                  enabled: !_writing,
                  decoration: InputDecoration(
                    labelText: "New comment"
                  ),
                )),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _writing ? null : () async {
                    setState(() => _writing = true);
                    final result = await _DreamComment.newComment(widget.dream.id, body: newCommentController.value.text);
                    setState(() => _writing = false);
                    if (result == true) newCommentController.clear();
                    setState(() {});
                  },
                )
              ],
            )
          ),
          FutureBuilder<List<DreamCommentRecord>>(
            builder: (context, snapshot) => snapshot.hasData ? _DreamCommentList(
              list: snapshot.data!,
              id: widget.dream.id,
              child: Column(children: [
                for (var comment in snapshot.data!) _DreamComment(comment)
              ]),
            ) : Container(/*render nothing*/),
            future: _DreamComment.loadFile(widget.dream.id),
          )
        ])
      )
    );
  }
}

class _DreamCommentList extends InheritedWidget {
  List<DreamCommentRecord> list;
  final String id;

  _DreamCommentList({
    this.list = const [],
    this.id = "",
    Key? key,
    required Widget child
  }) : super(key: key, child: child);

  static _DreamCommentList? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_DreamCommentList>();

  Future<void> save() async {
    final file = File(platformStorageDir.absolute.path + "/lldj-comments/$id.json");
    if (!await file.exists()) file.create();
    //if (await file.readAsString() == "") file.writeAsString("[]");
    List rawData = list;
    await file.writeAsString(jsonEncode(rawData.map((e) => e.toJSON()).toList()));
  }

  @override
  bool updateShouldNotify(covariant _DreamCommentList oldWidget) {
    return oldWidget.list != list;
  }
}

class _DreamComment extends StatefulWidget {
  static Future<List<DreamCommentRecord>> loadFile(String id) async {
    final file = File(platformStorageDir.absolute.path + "/lldj-comments/$id.json");
    if (!await file.exists()) return [];
    final String _out = await file.readAsString();
    List rawData = jsonDecode(_out == "" ? "[]" : _out);
    List<DreamCommentRecord> records = [];
    for (var record in rawData) {
      assert(record is Map);
      records.add(DreamCommentRecord(
        body: record["body"] ?? "__Error: missing comment body__",
        timestamp: record["timestamp"] ?? DateTime.fromMillisecondsSinceEpoch(-1)
      ));
    }
    records.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    records = records.reversed.toList();
    return records;
  }

  static Future<bool> newComment(String id, {required String body}) async {
    try {
      final file = File(platformStorageDir.absolute.path + "/lldj-comments/$id.json");
      if (!await file.exists()) await file.create();
      if (await file.readAsString() == "") file.writeAsString("[]");
      List rawData = jsonDecode(await file.readAsString());
      rawData.add({
        "body": body,
        "timestamp": DateTime.now().millisecondsSinceEpoch
      });
      file.writeAsString(jsonEncode(rawData));
    } catch(e) {
      return false;
    }
    return true;
  }

  final DreamCommentRecord comment;
  _DreamComment(this.comment, { Key? key }) : super(key: key);

  @override
  __DreamCommentState createState() => __DreamCommentState();
}

class __DreamCommentState extends State<_DreamComment> {
  List<DreamCommentRecord> _deletedComments = [];

  @override
  Widget build(BuildContext rootContext) {
    var _dateFormat = sharedPreferences.containsKey("datetime-format")
      ? sharedPreferences.getString("datetime-format") : DateTimeFormats.commonLogFormat;
    return _deletedComments.contains(widget.comment) ? Container() : InkWell(
      onLongPress: () => showDialog(context: rootContext, builder: (context) => Stack(
        alignment: Alignment.bottomCenter,
        children: [Positioned(
          bottom: 8,
          child: Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  child: Container(width: 360, child: Text("Edit"), alignment: Alignment.center),
                  onPressed: null//() => Get.back(),
                ),
                TextButton(
                  child: Container(width: 360, child: Text("Delete", style: TextStyle(color: Colors.red)), alignment: Alignment.center),
                  onPressed: () async {
                    _DreamCommentList.of(rootContext)?.list.removeWhere((element) => element.timestamp == widget.comment.timestamp);
                    _deletedComments.add(widget.comment);
                    await _DreamCommentList.of(rootContext)?.save();
                    Get.back();
                    setState(() => null);
                  },
                )
              ],
            ),
          ),
        )],
      )),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.comment.timestamp.format(_dateFormat ?? DateTimeFormats.commonLogFormat), style: Get.textTheme.caption),
            MarkdownBody(
              data: widget.comment.body,
              selectable: true,
              softLineBreak: true,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(height: 1.0),
            )
          ],
        )
      ),
    );
  }
}