import 'dart:convert';
import 'dart:ui';

import 'package:date_time_format/date_time_format.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal/db/dream.dart';
import 'package:journal/db/realm.dart';
import 'package:journal/views/editor.dart';
import 'package:journal/views/optional_features.dart';
import 'package:journal/views/details.dart' show DreamList;
import 'package:journal/views/realms/list.dart';
import 'package:journal/widgets/empty_state.dart';
import 'package:journal/main.dart';
import 'package:journal/widgets/gradienticon.dart';
import 'package:mdi/mdi.dart';
import 'package:url_launcher/url_launcher.dart';

class DreamListScreen extends StatefulWidget {
  DreamListScreen({
    Key? key
  }) : super(key: key);

  @override
  _DreamListScreenState createState() => _DreamListScreenState();
}

class _DreamListScreenState extends State<DreamListScreen> {
  late List<DreamRecord> list;
  bool isListInitialized = false;
  bool isSaving = false;

  Future<void> reloadDreamList() {
    List<DreamRecord> _list = [];
    List<Future> _futures = [];
    database.forEach((element) {
      var _ = DreamRecord(document: element);
      _futures.add(_.loadDocument());
      _list.add(_);
    });
    _list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    list = _list.reversed.toList();
    dreamList = list;
    isListInitialized = true;
    setState(() => isSaving = true);
    return databaseFile.writeAsString(jsonEncode(list.toListOfMap())).then((v) => setState(() => isSaving = false));
  }

  @override
  void initState() {
    super.initState();
    reloadDreamList();
    RealmListScreen.reloadRealmList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isSaving ? "Saving..." : "Dream Journal"),
        actions: [
          Tooltip(
            message: "Search",
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: Icon(Icons.search),
                onPressed: () => Get.toNamed("/search"),
                //color: Get.theme.colorScheme.secondary,
              ),
            ),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              if (OptionalFeatures.counters) PopupMenuItem(child: Row(
                children: [
                  Icon(Mdi.chartBar),
                  Padding(padding: EdgeInsets.all(8.0)),
                  Text("Statistics"),
                ],
                mainAxisSize: MainAxisSize.min,
              ), value: "/stats"),
              if (OptionalFeatures.realms) PopupMenuItem(child: Row(
                children: [
                  Icon(Icons.public),
                  Padding(padding: EdgeInsets.all(8.0)),
                  Text("Persistent Realms"),
                ],
                mainAxisSize: MainAxisSize.min,
              ), value: "/realms/list"),
              PopupMenuItem(
                child: Divider(),
                height: 8,
                padding: EdgeInsets.zero,
                enabled: false,
              ),
              PopupMenuItem(child: Row(
                children: [
                  Icon(Icons.settings),
                  Padding(padding: EdgeInsets.all(8.0)),
                  Text("Settings"),
                ],
                mainAxisSize: MainAxisSize.min,
              ), value: "/settings"),
              PopupMenuItem(child: Row(
                children: [
                  Icon(Icons.info),
                  Padding(padding: EdgeInsets.all(8.0)),
                  Text("About"),
                ],
                mainAxisSize: MainAxisSize.min,
              ), value: "/about")
            ],
            onSelected: (value) {Get.back(); if (value is String && value != "") Get.toNamed(value);},
            tooltip: "More...",
          )
          // IconButton(
          //   icon: Icon(Icons.settings),
          //   onPressed: () async {
          //     await Get.toNamed("/settings");
          //     setState(() => isListInitialized = false);
          //     await reloadDreamList();
          //   },
          // )
        ],
      ),
      body: isListInitialized ? 
        (list.length + migrationNotices.length) > 0 ? ListView.builder(
          itemBuilder: (_, i) => i < migrationNotices.length ? MaterialBanner(
            leading: Icon(Mdi.bullhorn, color: Get.theme.colorScheme.secondary),
            content: Text(migrationNotices[i]),
            actions: [
              IconButton(icon: Icon(Icons.close), onPressed: () => setState(() => migrationNotices.remove(migrationNotices[i])))
            ]
          ) : DreamEntry(dream: list[i-migrationNotices.length], list: list),
          itemCount: list.length + migrationNotices.length,
        ) : Center(child: EmptyState(
          icon: Icon(Icons.post_add),
          text: Text("This journal is a ghost town!\nWrite down some dreams!"),
        ))
      : FutureBuilder(
        builder: (context, snapshot) => snapshot.connectionState == ConnectionState.done ? Center(child: EmptyState(
          icon: Icon(Mdi.contentSaveAlertOutline),
          text: Text("The database could not be read.\n"
          "Maybe you imported the wrong file!\n"
          "Try importing a valid dream journal database file,\n"
          "or Burn the journal if you have to.")
        )) : Center(child: CircularProgressIndicator(value: null)),
        future: Future.delayed(Duration(seconds: 3)),
      ),
      bottomNavigationBar: isListInitialized ? BottomAppBar(
        child: Row(
          //buttonTextTheme: ButtonTextTheme.primary,
          children: [
            FutureBuilder(
              future: canLaunch("https://resources.dreamstation.one"),
              builder: (context, snapshot) => snapshot.data == true ? Tooltip(
                message: "Guides",
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    icon: Icon(Mdi.helpCircleOutline),
                    onPressed: () async => await launch("https://resources.dreamstation.one"),
                    color: Get.theme.colorScheme.secondary,
                  ),
                ),
              ) : Container(width: 0, height: 0)
            ),
            Expanded(child: Container(height: 0)),
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: IconButton(
            //     icon: Icon(Icons.nightlight),
            //     onPressed: () => Get.toNamed("/night/new"),
            //     color: Get.theme.accentColor,
            //   ),
            // ),
            if (OptionalFeatures.tags) Tooltip(
              message: "Tag a dream",
              child: IconButton(
                icon: Icon(Icons.tag),
                onPressed: () => Get.toNamed("/dreams/tag"),
                //style: ButtonStyle(foregroundColor: _Gold(), padding: _Padding(8)),
                color: Get.theme.colorScheme.secondary
              ),
            ),
            TextButton(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(children: [Icon(Icons.add), Container(width: 8, height: 0), Text("New Entry")], mainAxisSize: MainAxisSize.min),
              ),
              onPressed: () => Get.toNamed("/dreams/new"),
              style: ButtonStyle(foregroundColor: _Gold(), padding: _Padding(8)),
            ),
          ]
        ),
      ) : null,
    );
  }
}

class _Padding extends MaterialStateProperty<EdgeInsetsGeometry> {
  final double amount;
  _Padding(this.amount);

  @override
  resolve(Set<MaterialState> states) {
    return EdgeInsets.all(amount);
  }
}

class DreamEntry extends StatelessWidget {
  final CanBeSearchResult dream;
  final bool showCanonStatus;
  final List<DreamRecord>? list;

  DreamEntry({Key? key, required this.dream, this.list, this.showCanonStatus = false}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return dream is DreamRecord ? _buildDreamEntry(context, dream as DreamRecord)
    : /* dream is RealmRecord ? */ _buildRealmEntry(context, dream as RealmRecord);
  }

  Widget _buildDreamEntry(BuildContext context, DreamRecord dream) {
    var _dateFormat = sharedPreferences.containsKey("datetime-format")
      ? sharedPreferences.getString("datetime-format") : DateTimeFormats.commonLogFormat;
    var _nightFormat = sharedPreferences.containsKey("night-format")
      ? sharedPreferences.getString("night-format") ?? "M j" : "M j";
    return Column(children: [
      if (OptionalFeatures.nightly && list?.firstWhere((element) => element.night == dream.night) == dream) Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 8.0,
          vertical: 4.0
        ),
        child: Row(
          children: [
            Text(
              "Night of ${dream.night.format(_nightFormat)} to ${dream.night.add(Duration(days: 1)).format(_nightFormat)}",
              style: TextStyle(color: Get.theme.primaryColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      if (!dream.incomplete) ListTile(
        title: Text(dream.forgotten && dream.title == ""
            ? "No dream logged"
            : dream.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showCanonStatus && !dream.realmCanon) Text("Not canon", style: Get.textTheme.caption?.copyWith(fontStyle: FontStyle.italic, color: Colors.amber)),
            Text(dream.body, maxLines: 5, overflow: TextOverflow.fade),
          ],
        ),
        // leading: dream.lucid
        //     ? dream.wild
        //         ? GradientIcon(Mdi.weatherLightning, 24, goldGradient)
        //         : GradientIcon(Icons.cloud, 24, purpleGradient)
        //     : dream.forgotten
        //         ? Icon(Icons.cloud_off)
        //         : Icon(Icons.cloud_outlined),
        leading: dream.type.gradient == null ? Icon(dream.type.icon) 
        : GradientIcon(dream.type.icon, 24, dream.type.gradient!),
        onTap: () => Get.toNamed("/dreams/details", arguments: dream),
      ) else ListTile(
        title: Text("Finish this dream!"),
        subtitle: Text(
          "From " + dream.timestamp.format(_dateFormat ?? DateTimeFormats.commonLogFormat) +
          "\nTags: " + dream.tags.join(", "),
          maxLines: 5,
          overflow: TextOverflow.fade
        ),
        leading: Icon(Icons.info_outline_rounded),
        onTap: () => Get.toNamed("/dreams/complete", arguments: dream),
        onLongPress: () => Get.to(() => DreamEditor(mode: DreamEditMode.tag, dream: dream)),
      ),
      Divider(height: 1)
    ]);
  }
  Widget _buildRealmEntry(BuildContext context, RealmRecord realm) {
    return Column(children: [
      ListTile(
        title: Text(realm.title == "" ? "Untitled Persistent Realm" : realm.title),
        subtitle: Text(realm.body, maxLines: 2, overflow: TextOverflow.fade),
        leading: GradientIcon(Icons.public, 24, blueGreenGradient),
        onTap: () => Get.toNamed("/realms/details", arguments: dream),
      ),
      Divider(height: 1)
    ]);
  }
}

class _Gold extends MaterialStateColor {
  static Color _defaultColor = Colors.amber;
  static Color _pressedColor = Colors.amber.shade700;
  //static Color _hoverColor = Colors.amber.withAlpha(48);

  const _Gold() : super(0xffab47bc);

  @override
  Color resolve(Set<MaterialState> states) {
    if (states.contains(MaterialState.pressed)) {
      return _pressedColor;
    }
    return _defaultColor;
  }
}