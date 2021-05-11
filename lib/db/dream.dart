import 'package:objectdb/objectdb.dart';

class DreamRecord {
  final String id;
  final ObjectDB database;
  late Map _document;

  DreamRecord(this.id, {
    required ObjectDB database
  }) : database = database;

  Future<void> loadDocument() async => _document = await database.first({"_id": id});
  
  /// The dream's title.
  String get title => _document["title"] ?? "No title provided";
  set title(String value) => database.update(_document, {"title": value});

  /// The dream's "body," or summary.
  String get body => _document["body"] ?? "No body provided";
  set body(String value) => database.update(_document, {"body": value});

  /// Whether or not the dream was lucid.
  bool get lucid => _document["lucid"] ?? false;
  set lucid(bool value) => database.update(_document, {"lucid": value});

  /// If it is a lucid dream, whether or not it was wake-induced.
  bool get wild => _document["wild"] ?? false;
  set wild(bool value) => database.update(_document, {"wild": value});

  // /// The method used.
  // LucidDreamMethod? get method => _document["method"];
  // set method(LucidDreamMethod value) => _database.update(_document, {"method": value});

  /// Tags the user has applied to this dream.
  List<String> get tags => _document["tags"] ?? [];
  set tags(List<String> value) => database.update(_document, {"tags": value});
}