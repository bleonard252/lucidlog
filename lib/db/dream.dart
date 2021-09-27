import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:journal/main.dart';
import 'package:journal/views/optional_features.dart';
import 'package:mdi/mdi.dart';
import 'package:objectdb/objectdb.dart';

class DreamRecord {
  final String? id;
  //final ObjectDB database;
  late Map _document;

  String get temporaryIdForThisBuildOnly => _document["_id"];

  DreamRecord({this.id, Map? document}) :
  assert(id != null || document != null),
  this._document = document ?? {};

  Map toJSON() => _document;

  Future<void> loadDocument() async {
    if (this.id != null) _document = database.firstWhere((element) => element["_id"] == id);
    // /// WILD migration from flag to method
    // if (_document["wild"] == true && !methods.contains("WILD")) {
    //   await _update(_document, {
    //     Op.set: {"methods": [...(_document["methods"] ?? []), "WILD"]}
    //   });
    //   _document = await database.first({"_id": id});
    // }
  }
  
  /// The dream's title.
  String get title => _document["title"] ?? "No title provided";
  set title(String value) => _update(_document, {"title": value});

  /// The dream's "body," or summary.
  String get body => _document["body"] ?? "No body provided";
  set body(String value) => _update(_document, {"body": value});

  /// Whether or not the dream was lucid.
  bool get lucid => _document["lucid"] ?? false;
  set lucid(bool value) => _update(_document, {"lucid": value});

  /// Name, colors, and icons related to the dream category.
  _DreamType get type => _DreamType.withRecall(
    !this.forgotten,
    this.lucid ? (this.wild && OptionalFeatures.wildDistinction) ? _DreamType.wildLucid
      : _DreamType.dildLucid
    : _DreamType.nonLucid
  );

  /// The night during which the dream occurred.
  /// A "night," for the intent of recording dreams here,
  /// starts at noon and proceeds until noon the next day.
  /// This is used to group dreams in the main list.
  DateTime get night => DateTime(timestamp.year, timestamp.month, timestamp.hour > 12 ? timestamp.day : timestamp.day - 1);

  /// If it is a lucid dream, whether or not it was wake-induced.
  // @Deprecated("Use type instead.")
  // bool get wild => _document["wild"] ?? false;
  bool get wild => this.methods.contains("WILD") || this.methods.contains("SSILD") || methods.contains("DEILD");
  // set wild(bool value) => _update(_document, {"wild": value});

  /// If the dream was forgotten or otherwise not remembered with much integrity.
  /// Any details provided will still be shown.
  bool get forgotten => _document["forgotten"] ?? false;
  set forgotten(bool value) => _update(_document, {"forgotten": value});

  /// The date and time at which this dream was recorded.
  DateTime get timestamp => DateTime.fromMillisecondsSinceEpoch(_document.containsKey("timestamp") ? _document["timestamp"] : 0);
  set timestamp(DateTime value) => _update(_document, {"timestamp": value.millisecondsSinceEpoch});
  static final dtzero = DateTime.fromMillisecondsSinceEpoch(0);

  List<String> get methods => List.castFrom<dynamic, String>(_document["methods"] ?? []);
  set methods(List<String> value) => _update(_document, {"methods": value});

  // /// The method used.
  // LucidDreamMethod? get method => _document["method"];
  // set method(LucidDreamMethod value) => __update(_document, {"method": value});

  Future<void> delete() {
    return Future.value(database.remove(_document));
  }

  /// Tags the user has applied to this dream.
  /// Used for "tagging" dreams to recall them later.
  List<String> get tags => (_document["tags"] ?? []).whereType<String>().toList();
  set tags(List<String> value) => _update(_document, {"tags": value});

  /// Is the dream incompletely logged?
  /// This is set to `true` after tagging
  /// and `false` after journaling a tagged
  /// dream journal entry.
  /// This changes how the entry is shown on
  /// the Home and Search screens.
  bool get incomplete => _document["incomplete"] ?? false;
  set incomplete(bool value) => _update(_document, {"incomplete": value});

  void _update(Map query, Map patch) {
    var index = database.indexOf(_document);
    database[index] = {
      ..._document,
      ...patch
    };
    _document = database[index];
  }
}

class _DreamType {
  /// A gradient used in place of the grey
  /// background on the Details page and the
  /// white color of the icon on the List and Search pages.
  final Gradient? gradient;
  /// The name of the dream type, used in the Type area.
  /// If false, it falls back to another entry.
  final String name;
  /// The icon associated with the dream type.
  final IconData icon;

  const _DreamType._({
    this.gradient, 
    required this.name,
    required this.icon
  });

  /// Any non-lucid dream.
  static const nonLucid = _DreamType._(
    name: "Non-Lucid Dream",
    icon: Icons.cloud_outlined
  );
  /// Used in dreams of insufficient recall.
  /// A unique feature of this mode's display
  /// is that it does not appear in the
  /// Dream Type box, instead reverting to 
  /// its lucidity.
  _DreamType.withRecall(bool sufficient, _DreamType fallback) :
    this.name = fallback.name,
    this.icon = sufficient ? fallback.icon : Icons.cloud_off,
    this.gradient = fallback.gradient;
  
  /// A lucid dream. If WILD distinction is off,
  /// this shows for WILDs.
  static final dildLucid = _DreamType._(
    name: (OptionalFeatures.wildDistinction) ? "Dream-Induced Lucid Dream" : "Lucid Dream", 
    icon: Icons.cloud,
    gradient: purpleGradient
  );
  /// A WILD, if WILD distinction is on.
  static final wildLucid = _DreamType._(
    name: "Wake-Induced Lucid Dream",
    icon: Mdi.weatherLightning,
    gradient: goldGradient
  );
}