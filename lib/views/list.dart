import 'dart:math';
import 'dart:ui';

import 'package:date_time_format/date_time_format.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal/db/dream.dart';
import 'package:journal/views/optional_features.dart';
import 'package:journal/widgets/empty_state.dart';
import 'package:journal/main.dart';
import 'package:journal/widgets/gradienticon.dart';
import 'package:mdi/mdi.dart';
import 'package:objectdb/objectdb.dart';
import 'package:path_provider/path_provider.dart';
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

  Future<void> reloadDreamList() {
    //TODO: remove this section before v6!
    if (appVersion == "5") {
      return database.find({}).then<void>((value) async {
        List<DreamRecord> _list = [];
        List<Future> _futures = [];
        value.forEach((element) {
          var _ = DreamRecord(id: element["_id"]);
          _futures.add(_.loadDocument());
          _list.add(_);
        });
        await Future.wait(_futures);
        _list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        list = _list.reversed.toList();
        dreamList = list;
        isListInitialized = true;
        setState(() {});
      });
    } else {
      List<DreamRecord> _list = [];
      List<Future> _futures = [];
      databasev6.forEach((element) {
        var _ = DreamRecord(document: element);
        _futures.add(_.loadDocument());
        _list.add(_);
      });
      _list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      list = _list.reversed.toList();
      dreamList = list;
      isListInitialized = true;
      setState(() {});
      return Future.value();
    }
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
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Get.toNamed("/settings");
              setState(() {});
            },
          )
        ],
      ),
      body: isListInitialized ? 
      list.length > 0 ? ListView.builder(
        itemBuilder: (_, i) => DreamEntry(dream: list[i], list: list),
        itemCount: list.length,
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
            Tooltip(
              message: "Search",
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => Get.toNamed("/search"),
                  color: Get.theme.accentColor,
                ),
              ),
            ),
            FutureBuilder(
              future: canLaunch("https://ldr.1024256.xyz"),
              builder: (context, snapshot) => snapshot.data == true ? Tooltip(
                message: "Guides",
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    icon: Icon(Icons.map),
                    onPressed: () async => await launch("https://ldr.1024256.xyz"),
                    color: Get.theme.accentColor,
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
            Tooltip(
              message: "Tag a dream",
              child: IconButton(
                icon: Icon(Icons.tag),
                onPressed: () => Get.toNamed("/tag"),
                //style: ButtonStyle(foregroundColor: _Gold(), padding: _Padding(8)),
                color: Get.theme.accentColor
              ),
            ),
            TextButton(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(children: [Icon(Icons.add), Container(width: 8, height: 0), Text("New Entry")], mainAxisSize: MainAxisSize.min),
              ),
              onPressed: () => Get.toNamed("/new"),
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
  final DreamRecord dream;
  final List<DreamRecord>? list;

  DreamEntry({Key? key, required this.dream, this.list}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
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
        subtitle: Text(dream.body, maxLines: 5, overflow: TextOverflow.fade),
        // leading: dream.lucid
        //     ? dream.wild
        //         ? GradientIcon(Mdi.weatherLightning, 24, goldGradient)
        //         : GradientIcon(Icons.cloud, 24, purpleGradient)
        //     : dream.forgotten
        //         ? Icon(Icons.cloud_off)
        //         : Icon(Icons.cloud_outlined),
        leading: dream.type.gradient == null ? Icon(dream.type.icon) 
        : GradientIcon(dream.type.icon, 24, dream.type.gradient!),
        onTap: () => Get.toNamed("/details", arguments: dream),
      ) else ListTile(
        title: Text("Finish this dream!"),
        subtitle: Text(
          "From " + dream.timestamp.format(_dateFormat ?? DateTimeFormats.commonLogFormat) +
          "\nTags: " + dream.tags.join(", "),
          maxLines: 5,
          overflow: TextOverflow.fade
        ),
        leading: Icon(Icons.info_outline_rounded),
        onTap: () => Get.toNamed("/complete", arguments: dream),
      ),
      Divider(height: 1)
    ]);
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