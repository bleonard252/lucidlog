import 'dart:convert';
import 'dart:io';

import 'package:date_time_format/date_time_format.dart';
import 'package:file_picker/file_picker.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal/main.dart';
import 'package:journal/migrations/databasev6.dart';
import 'package:journal/views/methods.dart';
import 'package:journal/views/optional_features.dart';
import 'package:mdi/mdi.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart' as Settings;
import 'package:tar/tar.dart';

enum _ExportType {
  /// a `.db` file from Version 5 and prior
  v5,
  /// a `.json` file from Version 6 Beta 1
  v6Beta1,
  /// a `.lldj` archive from Version 6 Beta 2 and forward
  v6Lldj
}

class SettingsRoot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Settings.SettingsScreen(
      title: "Settings",
      children: [
        Settings.SwitchSettingsTile(
          title: "AMOLED Dark Mode",
          subtitle: "Sets the background to pure black, saving battery and maybe your eyeballs on AMOLED devices.",
          settingKey: "amoled-dark",
          icon: Icon(Icons.nights_stay),
        ),
        // if (!GetPlatform.isIOS) Settings.SettingsTile(
        //   title: "Log Storage Filename",
        //   subtitle: "This will NOT move the file! ALL YOUR DATA WILL BE LOST!",
        //   icon: Icon(Icons.folder),
        // )
        Settings.SimpleSettingsTile(
          title: "Optional features",
          icon: Icon(Mdi.featureSearch),
          subtitle: "WILD Distinction, grouping entries by night, and other features that might "
          "be too confusing for some users or get in the way",
          screen: OptionalFeaturesSettingsScreen(),
        ),
        Settings.RadioSettingsTile(
          settingKey: "datetime-format",
          title: "Date format",
          expandable: true,
          icon: Icon(Icons.date_range, color: Get.iconColor),
          defaultKey: AmericanDateTimeFormats.abbrDayOfWeekAbbr,
          values: {
            AmericanDateTimeFormats.abbrDayOfWeekAbbr: "Tue Nov 5, 2019 7:42 pm",
            EuropeanDateTimeFormats.abbrDayOfWeekAbbr: "Tue 5 Nov 2019 19:42",
            AmericanDateTimeFormats.short: "11/05/2019 7:42 pm",
            EuropeanDateTimeFormats.short: "05/11/2019 19:42"
          },
        ),
        if (OptionalFeatures.nightly) Settings.RadioSettingsTile(
          settingKey: "night-format",
          title: "Format for night headers",
          expandable: true,
          icon: Icon(Mdi.weatherNight, color: Get.iconColor),
          defaultKey: r"M j",
          values: {
            r"M j": "Nov 5",
            r"j M": "5 Nov",
            r"m/d": "11/05",
            r"d/m": "05/11"
          },
        ),
        if (OptionalFeatures.rememberMethods) Settings.SimpleSettingsTile(
          title: "Techniques",
          subtitle: "Used to remember what techniques you used to become lucid.",
          icon: Icon(Mdi.viewList),
          // children: [
          //   Padding(
          //     padding: const EdgeInsets.all(16.0),
          //     child: TextField(
          //       controller: TextEditingController(text: sharedPreferences.getStringList("ld-methods")?.join("\n") ?? ""),
          //       onChanged: (v) => sharedPreferences.setStringList("ld-methods", v.split("\n")),
          //       minLines: null,
          //       maxLines: null,
          //     ),
          //   )
          // ],
          screen: MethodsSettingsScreen(),
        ),
        Settings.SettingsTileGroup(
          title: "Storage",
          children: [
            ListTile(
              title: Text("Storage path"),
              subtitle: Text(platformStorageDir.absolute.path),
              leading: Icon(Icons.sd_storage)
            ),
            Divider(height: 0.0),
            if (GetPlatform.isAndroid || GetPlatform.isDesktop) ...[ListTile(
              leading: Icon(Icons.save),
              title: Text("Export"),
              subtitle: Text("Save a copy of your dream journal's database."),
              onTap: () async {
                // var encoder = ZipFileEncoder();
                // encoder.create(Directory.systemTemp.absolute.path + "/export.zip");
                // encoder.addDirectory(Directory(platformStorageDir.absolute.path + "/lldj-comments/"));
                // encoder.addFile(databaseFile);
                // encoder.close();
                final outfile = File(platformStorageDir.absolute.path + "/export.tgz");
                final tarEntries = Stream<TarEntry>.fromIterable([
                  TarEntry(TarHeader(name: "dreamjournal.json"), databaseFile.openRead()),
                  // Add the PRs file here at some point
                  await for (var file in Directory(platformStorageDir.absolute.path + "/lldj-comments/").list())
                    if (file is File) TarEntry(TarHeader(name: "lldj-comments/"+file.uri.pathSegments.last), file.openRead()),
                  await for (var file in Directory(platformStorageDir.absolute.path + "/lldj-plotlines/").list())
                    if (file is File) TarEntry(TarHeader(name: "lldj-plotlines/"+file.uri.pathSegments.last), file.openRead())
                ]).transform(tarWriter).transform(gzip.encoder);
                if (GetPlatform.isAndroid) {
                  await tarEntries.pipe(outfile.openWrite());
                  final newfile = await File(platformStorageDir.absolute.path + "/export.tgz").copy(
                    (await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOADS))
                    + "/dreamjournal-${DateTime.now().millisecondsSinceEpoch}.lldj");
                  Get.dialog(AlertDialog(
                    title: Text("File exported to Downloads"),
                    content: SelectableText(newfile.absolute.path),
                    actions: [TextButton(child: Text("OK"), onPressed: () => Get.back())],
                  ));
                } else if (GetPlatform.isDesktop) {
                  var filename = await FilePicker.platform.saveFile(
                    dialogTitle: "Save dream journal database",
                    allowedExtensions: ["lldj"],
                    fileName: "dreamjournal.lldj"
                  );
                  if (filename != null) await tarEntries.pipe(File(filename).openWrite());
                }
              },
            ), Divider(height: 0.0)],
            if (GetPlatform.isAndroid || GetPlatform.isDesktop) ...[ListTile(
              leading: Icon(Icons.folder),
              title: Text("Import"),
              subtitle: Text("Load a backup of your dream journal's database, overwriting it."),
              onTap: () async {
                //FilePickerCross(File.fromUri(Uri.parse(sharedPreferences.getString("storage-path") ?? "")).readAsBytesSync()).exportToStorage(fileName: "dreamjournal.db");
                try {
                  final type = await Get.dialog<_ExportType>(AlertDialog(
                    title: Text("Select type to import"),
                    content: Text("Select from one of the following backup types. v5 .db files are no longer supported and may disappear at any point."),
                    actions: [
                      TextButton(onPressed: () => Get.back(result: _ExportType.v5), child: Text("Version 5 (.db)")),
                      TextButton(onPressed: () => Get.back(result: _ExportType.v6Beta1), child: Text("Version 6 Beta 1 (.json)")),
                      TextButton(onPressed: () => Get.back(result: _ExportType.v6Lldj), child: Text("Version 6 (.lldj)")),
                      TextButton(onPressed: () => Get.back(result: null), child: Text("Cancel import")),
                    ],
                  ));
                  if (type == null) return;
                  final file = (await FilePicker.platform.pickFiles(
                    allowedExtensions: [
                      type == _ExportType.v5 ? "*.db"
                      : type == _ExportType.v6Beta1 ? "*.json"
                      : "*.lldj"
                    ],
                    dialogTitle: "Select your dream journal backup",
                    allowMultiple: false,
                    withData: true,
                  ))?.files[0];
                  late final bool confirmation;
                  if (type == _ExportType.v6Lldj) confirmation = true;
                  else confirmation = await Get.dialog(AlertDialog(
                    title: Text("Are you sure you want to import this?"),
                    content: Text("Importing this WILL clear your entire journal! Make sure you've performed a backup, and make sure you are importing the correct file.\n"
                    "No checks are done to make sure you're importing valid data, so you have to do it yourself!"),
                    actions: [
                      TextButton(onPressed: () => Get.back(result: false), child: Text("STAY SAFE")),
                      TextButton(onPressed: () => Get.back(result: true), child: Text("YES", style: TextStyle(color: Colors.red))),
                    ],
                  ));
                  if (confirmation == false && file != null) return;
                  if (type == _ExportType.v6Lldj) {
                    final reader = TarReader(File(file!.path!).openRead().transform(gzip.decoder));
                    while (await reader.moveNext()) {
                      final entry = reader.current;
                      //print(entry.name);
                      if (entry.name == "dreamjournal.json") {
                        //await databaseFile.openWrite().addStream(entry.contents);
                        late final List _importedDreams;
                        late final List _dreams;
                        try {
                          _importedDreams = jsonDecode(await entry.contents.transform(utf8.decoder).fold("", (previous, element) => previous+element));
                          //print(_importedDreams);
                          _dreams = [
                            for (var dream in database) if (!_importedDreams.map((element) => element["_id"]).contains(dream["_id"])) dream,
                            for (var dream in _importedDreams) dream
                          ];
                        } on Exception {
                          _dreams = database;
                        }
                        database.clear();
                        database.addAll(_dreams.toList());
                        await databaseFile.writeAsString(jsonEncode(_dreams), flush: true);
                        //print(_dreams);
                      } else if (entry.name.startsWith("lldj-plotlines/")) {
                        // Plotlines information always overrides, as these are simply
                        // an addition to the entry itself.
                        // This is unlike comments, which may be individually edited
                        // and deleted.
                        await File(platformStorageDir.absolute.path + "/" + entry.name).openWrite().addStream(entry.contents);
                      } else if (entry.name.startsWith("lldj-comments/")) {
                        final _commentFile = await File(platformStorageDir.absolute.path + "/" + entry.name).readAsString();
                        late final List _importedComments;
                        late final List _comments;
                        try {
                          _importedComments = jsonDecode(await entry.contents.transform(utf8.decoder).fold("", (previous, element) => previous+element));
                          var __comments = jsonDecode(_commentFile);
                          _comments = [
                            ..._importedComments,
                            for (var comment in __comments) if (!_importedComments.map((element) => element["timestamp"]).contains(comment["timestamp"])) comment
                          ];
                        } on Exception{
                          _comments = [];
                        }
                        await File(platformStorageDir.absolute.path + "/" + entry.name).writeAsString(jsonEncode(_comments));
                      }
                    }
                  } else if (type == _ExportType.v5) {
                    await databaseMigrationVersion6(v5FPath: file!.path!);
                  } else if (type == _ExportType.v6Beta1) await File(platformStorageDir.absolute.path + "/dreamjournal.json").writeAsBytes(file!.bytes!);
                  // await Get.dialog(AlertDialog(
                  //   title: Text("Immediate restart required"),
                  //   content: Text("The app will now restart to finish applying this change."),
                  //   actions: [
                  //     TextButton(onPressed: () => exit(0), child: Text("OK")),
                  //   ],
                  // ));
                } catch(_) {
                  return;
                }
              },
            ), Divider(height: 0.0)],
            ...[ListTile(
              leading: Icon(Mdi.fire, color: Colors.red),
              title: Text("Burn", style: TextStyle(color: Colors.red)),
              subtitle: Text("Remove all journal entries.", style: TextStyle(color: Colors.red)),
              onTap: () async {
                //FilePickerCross(File.fromUri(Uri.parse(sharedPreferences.getString("storage-path") ?? "")).readAsBytesSync()).exportToStorage(fileName: "dreamjournal.db");
                final confirmation = await Get.dialog(AlertDialog(
                  title: Text("Are you sure you want to import this?"),
                  content: Text("Burning the database WILL clear your entire journal! Make sure you've performed a backup."),
                  actions: [
                    TextButton(onPressed: () => Get.back(result: false), child: Text("STAY SAFE")),
                    TextButton(onPressed: () => Get.back(result: true), child: Text("YES", style: TextStyle(color: Colors.red))),
                  ],
                ));
                if (confirmation == false) return;
                await File(platformStorageDir.absolute.path + "/dreamjournal.json").delete();
                await Get.dialog(AlertDialog(
                  title: Text("Immediate restart required"),
                  content: Text("The app will now restart to finish applying this change."),
                  actions: [
                    TextButton(onPressed: () => exit(0), child: Text("OK")),
                  ],
                ));
              },
            ), Divider(height: 0.0)]
          ]
        ),
        // if (canUseNotifications == true) Settings.SettingsTileGroup(
        //   title: "Notifications",
        //   children: [
        //     ListTile(
        //       title: Text("Test Notification"),
        //       leading: Icon(Icons.notifications_active),
        //       onTap: () => RealityCheck.schedule(),
        //     ),
        //     Divider(height: 0.0),
        //   ],
        // ),
      ]
    );
  }
}