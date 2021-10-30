import 'package:journal/db/dream.dart' show CanBeSearchResult, DreamRecord, RecordWithId;
import 'package:journal/main.dart';

class RealmRecord with CanBeSearchResult implements RecordWithId {
  final String? _id;
  //final ObjectDB realmDatabase;
  late Map _document;

  String get id => _document["_id"];

  RealmRecord({String? id, Map? document}) :
  assert(id != null || document != null),
  this._id = id,
  this._document = document ?? {};

  Map toJSON() => _document;

  Future<void> loadDocument() async {
    if (this._id != null) _document = realmDatabase.firstWhere((element) => element["_id"] == _id);
  }
  
  /// The PR's title.
  String get title => _document["title"] ?? "No title provided";
  set title(String value) => _update(_document, {"title": value});

  /// The PR's summary.
  String get body => _document["body"] ?? "No body provided";
  set body(String value) => _update(_document, {"body": value});

  /// The date and time of this PR's first dream.
  DateTime get timestamp => DateTime.fromMillisecondsSinceEpoch(_document.containsKey("timestamp") ? _document["timestamp"] : 0);
  set timestamp(DateTime value) => _update(_document, {"timestamp": value.millisecondsSinceEpoch});

  Future<void> delete() {
    return Future.value(realmDatabase.remove(_document));
  }

  List<RealmSubrecord> get characters => (_document["characters"] ?? []).map<RealmSubrecord>((v) => RealmSubrecord(name: v["name"], body: v["body"]));
  set characters(List<RealmSubrecord> value) => _document["characters"] = value.map<dynamic>((v) => v.toJSON());

  List<DreamRecord> includedDreams([List<DreamRecord>? list]) {
    list = list ?? dreamList;
    var _list = list.where((e) => e.realm == _id).toList();
    _list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    this.timestamp = _list.last.timestamp;
    return _list.reversed.toList();
  }

  void _update(Map query, Map patch) {
    var index = realmDatabase.indexOf(_document);
    realmDatabase[index] = {
      ..._document,
      ...patch
    };
    _document = realmDatabase[index];
  }
}

class RealmSubrecord {
  final String? name;
  final String body;
  RealmSubrecord({this.name, required this.body});

  Map toJSON() => {
    "name": this.name,
    "body": this.body
  };
}