
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal/db/realm.dart';
import 'package:journal/main.dart';
import 'package:journal/views/list.dart';
import 'package:journal/views/realms/details.dart';
import 'package:journal/widgets/empty_state.dart';
import 'package:mdi/mdi.dart';

class RealmListScreen extends StatefulWidget {
  RealmListScreen({
    Key? key
  }) : super(key: key);

  static Future<void> reloadRealmList() {
    List<RealmRecord> _list = [];
    realmDatabase.forEach((element) {
      var _ = RealmRecord(document: element);
      _.loadDocument();
      _list.add(_);
    });
    _list.forEach((element) => element.includedDreams());
    _list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    var list = _list.reversed.toList();
    realmList = list;
    return realmDatabaseFile.writeAsString(jsonEncode(list.toListOfMap()));
  }

  @override
  _RealmListScreenState createState() => _RealmListScreenState();
}

class _RealmListScreenState extends State<RealmListScreen> {
  late List<RealmRecord> list;
  bool isListInitialized = false;
  bool isSaving = false;

  Future<void> reloadRealmList() {
    List<RealmRecord> _list = [];
    realmDatabase.forEach((element) {
      var _ = RealmRecord(document: element);
      _.loadDocument();
      _list.add(_);
    });
    _list.forEach((element) => element.includedDreams());
    _list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    list = _list.reversed.toList();
    realmList = list;
    isListInitialized = true;
    setState(() => isSaving = true);
    return realmDatabaseFile.writeAsString(jsonEncode(list.toListOfMap())).then((v) => setState(() => isSaving = false));
  }

  @override
  void initState() {
    super.initState();
    reloadRealmList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isSaving ? "Saving..." : "Persistent Realms"),
      ),
      body: isListInitialized ? 
      list.length > 0 ? ListView.builder(
        itemBuilder: (_, i) => DreamEntry(dream: list[i]),
        itemCount: list.length,
      ) : Center(child: EmptyState(
        icon: Icon(Mdi.earthPlus),
        text: Text("You don't have any PRs documented.\nYet."),
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
            Expanded(child: Container(height: 0)),
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: IconButton(
            //     icon: Icon(Icons.nightlight),
            //     onPressed: () => Get.toNamed("/night/new"),
            //     color: Get.theme.accentColor,
            //   ),
            // ),
            TextButton(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(children: [Icon(Icons.add), Container(width: 8, height: 0), Text("New PR")], mainAxisSize: MainAxisSize.min),
              ),
              onPressed: () async {
                await Get.toNamed("/realms/new");
                await reloadRealmList();
                setState(() {});
              },
              style: ButtonStyle(foregroundColor: _BlueGreen(), padding: _Padding(8)),
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

class _BlueGreen extends MaterialStateColor {
  static Color _defaultColor = Colors.teal;
  static Color _pressedColor = Colors.teal.shade700;
  //static Color _hoverColor = Colors.amber.withAlpha(48);

  const _BlueGreen() : super(0xff009688);

  @override
  Color resolve(Set<MaterialState> states) {
    if (states.contains(MaterialState.pressed)) {
      return _pressedColor;
    }
    return _defaultColor;
  }
}