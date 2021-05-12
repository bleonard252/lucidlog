import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal/db/dream.dart';
import 'package:journal/empty_state.dart';
import 'package:journal/main.dart';
import 'package:journal/widgets/gradienticon.dart';
import 'package:mdi/mdi.dart';
import 'package:objectdb/objectdb.dart';
import 'package:path_provider/path_provider.dart';

class DreamListScreen extends StatefulWidget {
  @override
  _DreamListScreenState createState() => _DreamListScreenState();
}

class _DreamListScreenState extends State<DreamListScreen> {
  late List<DreamRecord> list;
  bool isListInitialized = false;

  Future<void> reloadDreamList() {
    return database.find({}).then<void>((value) {
      List<DreamRecord> _list = [];
      value.forEach((element) {
        var _ = DreamRecord(element["_id"], database: database);
        _.loadDocument();
        _list.add(_);
      });
      list = _list;
      isListInitialized = true;
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    reloadDreamList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dream Journal"),
        shadowColor: Get.theme.primaryColor,
        backgroundColor: Get.theme.canvasColor,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Get.toNamed("/settings"),
          )
        ],
      ),
      body: isListInitialized ? 
      list.length > 0 ? ListView.builder(
        itemBuilder: (_, i) => _Entry(dream: list[i]),
        itemCount: list.length,
      ) : Center(child: EmptyState(
        icon: Icon(Icons.post_add),
        text: Text("This journal is a ghost town!\nWrite down some dreams!"),
      ))
      : Center(child: CircularProgressIndicator(value: null)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: isListInitialized ? FloatingActionButton.extended(
        label: Text("New Entry"),
        icon: Icon(Icons.add),
        onPressed: () => Get.toNamed("/new"),
      ) : null
    );
  }
}

class _Entry extends StatelessWidget {
  final DreamRecord dream;

  _Entry({Key? key, required this.dream}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(dream.title),
      subtitle: Text(dream.body),
      leading: dream.lucid ? dream.wild ? GradientIcon(Mdi.weatherLightning, 24, goldGradient)
      : GradientIcon(Icons.cloud, 24, purpleGradient) 
      : Icon(Icons.cloud_outlined),
      onTap: () => Get.toNamed("/details", arguments: dream),
    );
  }
}
