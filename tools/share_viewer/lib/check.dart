import 'dart:convert';
import 'package:file/file.dart';
import 'package:journal/db/dream.dart';
import 'package:journal/db/realm.dart';
import 'package:journal/sharing/lldj.dart';
import 'package:lldj_share_viewer/main.dart';
import 'package:tar/tar.dart';

Future<RealmOrDream?> checkUploadedFile(TarReader reader) async {
  RealmRecord? realm;
  DreamRecord? dream;
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
      dream = DreamRecord(
        document: json.decode(
          (await entry.contents.transform(Utf8Decoder()).toList())
          .join("")
        )
      );
    } else if (entry.name == ".lldj-realm-share") {
      // Same as the above but it makes a realm record out of it.
      // There is another file that holds the PR's included dreams,
      // should the exporter choose to include it.
      await temporaryProfileFS.file("/.lldj-realm-share").openWrite().addStream(entry.contents);
      realm = SharedRealmRecord(
        document: json.decode(
          (await entry.contents.transform(Utf8Decoder()).toList())
          .join("")
        )
      );
    } else if (entry.name.startsWith("lldj-plotlines/")) {
      // Plotlines information always overrides, as these are simply
      // an addition to the entry itself.
      // This is unlike comments, which may be individually edited
      // and deleted.
      //await File(tempProfile.absolute.path + "/" + entry.name).openWrite().addStream(entry.contents);
      await temporaryProfileFS.file("/"+entry.name).openWrite().addStream(entry.contents);
    }
  }
  assert(realm != null || dream != null, "Invalid file");
  return (realm != null || dream != null) ? RealmOrDream(
    realm: realm,
    dream: dream
  ) : null;
}

class SharedDreamRecord extends DreamRecord {
  SharedDreamRecord({document: Map}) : super(document: document);
  @override
  File get plotFile => temporaryProfileFS.file("/lldj-plotlines/"+id+".json");
}
class SharedRealmRecord extends RealmRecord {
  SharedRealmRecord({document: Map}) : super(document: document);
  @override
  File get extraFile => temporaryProfileFS.file("/.lldj-realm-share");
}