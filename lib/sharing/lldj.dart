import 'dart:convert';
import 'dart:io';

import 'package:journal/db/dream.dart';
import 'package:journal/db/realm.dart';
import 'package:journal/main.dart';
import 'package:journal/sharing/incoming.dart';
import 'package:tar/tar.dart';

Stream<List<int>> shareDreamLLDJ(DreamRecord dream) {
  return Stream<TarEntry>.fromIterable([
    TarEntry(TarHeader(name: ".lldj-dream-share"), Stream.value(json.encode(dream.toJSON()).codeUnits)),
    if (dream.plotFile.existsSync()) TarEntry(TarHeader(name: "lldj-plotlines/"+dream.id+".json"), dream.plotFile.openRead())
  ]).transform(tarWriter).transform(gzip.encoder);
}
Stream<List<int>> shareRealmLLDJ(RealmRecord realm) {
  return Stream<TarEntry>.fromIterable([
    TarEntry(TarHeader(name: ".lldj-realm-share"), Stream.value(json.encode(realm.includedDreams()).codeUnits)),
    TarEntry(TarHeader(name: "lldj-realmjournal.json"), Stream.value(json.encode(realm.toJSON()).codeUnits)),
    for (var dream in realm.includedDreams()) 
      if (dream.plotFile.existsSync()) TarEntry(TarHeader(name: "lldj-plotlines/"+dream.id+".json"), dream.plotFile.openRead())
  ]).transform(tarWriter).transform(gzip.encoder);
}

class RealmOrDream {
  RealmRecord? realm;
  DreamRecord? dream;

  RealmOrDream({
    this.realm,
    this.dream
  }) : assert(realm != null || dream != null, "You should ALWAYS have either a PR or dream entry added.");
}

@deprecated
Future<RealmOrDream?> checkFile() async {
  if (importedFile == null) return null;
  var tempProfile = Directory(platformStorageDir.absolute.path + "/lldj-temp-profile/");
  final reader = TarReader(importedFile!.openRead().transform(gzip.decoder));
  while (await reader.moveNext()) {
    final entry = reader.current;
    //print(entry.name);
    if (entry.name == "dreamjournal.json") {
      // This is a dream journal archive file.
      // It cannot be opened as a share.
      // The import handler will have to handle this.
      return null;
    } else if (entry.name == ".lldj-dream-share") {
      // The following spaghetti code collects the bytes,
      // turns them all into a usable Map, then makes a
      // dream record out of it.
      return RealmOrDream(dream: DreamRecord(
        document: json.decode(
          (await entry.contents.transform(Utf8Decoder()).toList())
          .join("")
        )
      ));
    } else if (entry.name == ".lldj-realm-share") {
      // Same as the above but it makes a realm record out of it.
      // There is another file that holds the PR's included dreams,
      // should the exporter choose to include it.
      return RealmOrDream(realm: RealmRecord(
        document: json.decode(
          (await entry.contents.transform(Utf8Decoder()).toList())
          .join("")
        )
      ));
    } else if (entry.name.startsWith("lldj-plotlines/")) {
      // Plotlines information always overrides, as these are simply
      // an addition to the entry itself.
      // This is unlike comments, which may be individually edited
      // and deleted.
      await File(tempProfile.absolute.path + "/" + entry.name).openWrite().addStream(entry.contents);
    }
  }
}