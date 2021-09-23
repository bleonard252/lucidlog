import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal/db/dream.dart';
import 'package:journal/widgets/empty_state.dart';
import 'package:journal/main.dart';
import 'package:journal/widgets/gradienticon.dart';
import 'package:mdi/mdi.dart';
import 'package:objectdb/objectdb.dart';
import 'package:path_provider/path_provider.dart';

import 'list.dart' show DreamEntry;
//late List<DreamRecord> dreamList;

enum SearchListMode {
  /// A text-based search in the title or body.
  search,
  /// A filter or list with a displayed title.
  /// Shows a list of recorded **dreams**.
  listOrFilter
}

class SearchScreen extends StatefulWidget {
  final SearchListMode mode;
  late final String title;

  SearchScreen({this.mode = SearchListMode.search, this.title = ""});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<DreamRecord> list = [];
  late TextEditingController controller;

  Future<void> reloadDreamList() async {
    // //TODO: remove this section before v6!
    // if (appVersion == "5") {
    //   return database.find({}).then<void>((value) async {
    //     List<DreamRecord> _list = [];
    //     List<Future> _futures = [];
    //     value.where((document) => document['title'].contains(controller.value.text) || document['body'].contains(controller.value.text))
    //     .forEach((element) {
    //       var _ = DreamRecord(id: element["_id"]);
    //       _futures.add(_.loadDocument());
    //       _list.add(_);
    //     });
    //     await Future.wait(_futures);
    //     _list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    //     list = _list.reversed.toList();
    //     if (controller.value.text == "") list = [];
    //     //dreamList = list;
    //     setState(() {});
    //   });
    // } else {
    //   List<DreamRecord> _list = [];
    //   List<Future> _futures = [];
    //   databasev6.where((document) => document['title'].contains(controller.value.text) || document['body'].contains(controller.value.text))
    //   .forEach((element) {
    //     var _ = DreamRecord(document: element);
    //     _futures.add(_.loadDocument());
    //     _list.add(_);
    //   });
    //   _list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    //   list = _list.reversed.toList();
    //   if (controller.value.text == "") list = [];
    //   //dreamList = list;
    //   setState(() {});
    //   return Future.value();
    // }
    list = dreamList.where((document) => document.title.contains(controller.value.text) || document.body.contains(controller.value.text)).toList();
    if (controller.value.text == "") list = [];
    setState(() {});
  }

  // Future<void> reloadDreamList() {
  //   // TODO: actually perform a search
  //   return database.find({}).then<void>((value) async {
  //     List<DreamRecord> _list = [];
  //     List<Future> _futures = [];
  //     value.where((document) => document['title'].contains(controller.value.text) || document['body'].contains(controller.value.text))
  //     .forEach((element) {
  //       var _ = DreamRecord(id: element["_id"]);
  //       _futures.add(_.loadDocument());
  //       _list.add(_);
  //     });
  //     await Future.wait(_futures);
  //     _list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  //     list = _list.reversed.toList();
  //     if (controller.value.text == "") list = [];
  //     setState(() {});
  //   });
  // }

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    reloadDreamList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.mode == SearchListMode.listOrFilter ? Text(widget.title)
        : TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Search",
            border: InputBorder.none
          ),
          onChanged: (v) => reloadDreamList(),
        )
      ),
      body: list.length > 0 ? ListView.builder(
        itemBuilder: (_, i) => DreamEntry(dream: list[i]),
        itemCount: list.length,
      ) : controller.value.text == "" ? ListView(children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("Warning: these buttons don't work yet! The below serves as a preview for features I expect to add in the future.\n"
          + "However, regular search works exactly how you expect it to."),
        ),
        ListTile(
          leading: GradientIcon(Icons.cloud, 24.0, purpleGradient),
          title: Text("Filter to Lucid Only"),
          subtitle: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Filter to show lucid dreams only"),
              Wrap(
                children: [
                  TextButton(
                    onPressed: null,
                    child: Text("Filter to Non-Lucid Only"),
                    //style: ButtonStyle(foregroundColor: _Gold())
                  ),
                  Container(width: 16, height: 0),
                  TextButton(
                    onPressed: null,
                    child: Text("Filter to WILD Only"),
                    //style: ButtonStyle(foregroundColor: _Gold())
                  ),
                  Container(width: 16, height: 0),
                  TextButton(
                    onPressed: null,
                    child: Text("Filter to DILD Only"),
                    //style: ButtonStyle(foregroundColor: _Gold())
                  ),
                ],
              )
            ],
          ),
        ),
        ListTile(
          leading: Icon(Icons.public),
          title: Text("List Persistent Realms"),
          subtitle: Text("A tool for the talented."),
        ),
        ListTile(
          leading: Icon(Icons.dark_mode),
          title: Text("By Night"),
          subtitle: Text("Search by date"),
        ),
        ListTile(
          leading: Icon(Icons.cloud_off),
          title: Text("List Insufficient Recall"),
          subtitle: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Find dreams with low recall, and try to finish them."),
              TextButton(
                onPressed: null,
                child: Text("List Sufficient Recall"),
                //style: ButtonStyle(foregroundColor: _Gold()),
              )
            ],
          ),
        )
      ]) : Center(child: EmptyState(
        icon: Icon(Icons.search_off),
        text: Text("The search uncovered no results. Try revising your search."),
      ),)
    );
  }
}

class _Gold extends MaterialStateColor {
  static Color _defaultColor = Colors.amber;
  static Color _pressedColor = Colors.amber.shade700;
  static Color _hoverColor = Colors.amber.withAlpha(48);

  const _Gold() : super(0xffab47bc);

  @override
  Color resolve(Set<MaterialState> states) {
    if (states.contains(MaterialState.pressed)) {
      return _pressedColor;
    }
    return _defaultColor;
  }
}