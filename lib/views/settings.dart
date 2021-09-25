import 'dart:io';
import 'dart:typed_data';

import 'package:date_time_format/date_time_format.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_picker_cross/file_picker_cross.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal/main.dart';
import 'package:journal/notifications.dart';
import 'package:journal/views/methods.dart';
import 'package:journal/views/optional_features.dart';
import 'package:mdi/mdi.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart' as Settings;
import 'package:url_launcher/url_launcher.dart';

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
        ListTile(
          title: Text("About"),
          leading: Icon(Icons.info),
          onTap: () => Get.toNamed("/about"),
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
                FilePickerCross(File(platformStorageDir.absolute.path + (appVersion == "5" ? "/dreamjournal.db" : "/dreamjournal.json")).readAsBytesSync())
                .exportToStorage(fileName: appVersion == "5" ? "/dreamjournal.db" : "/dreamjournal.json");
              },
            ), Divider(height: 0.0)],
            if (GetPlatform.isAndroid || GetPlatform.isDesktop) ...[ListTile(
              leading: Icon(Icons.folder),
              title: Text("Import"),
              subtitle: Text("Load a backup of your dream journal's database, overwriting it."),
              onTap: () async {
                //FilePickerCross(File.fromUri(Uri.parse(sharedPreferences.getString("storage-path") ?? "")).readAsBytesSync()).exportToStorage(fileName: "dreamjournal.db");
                try {
                  await Get.dialog(AlertDialog(
                    title: Text("Import warning"),
                    content: Text("""The database has changed recently and the file is now a ".json", NOT a ".db". ".db" files are no longer supported for import."""),
                    actions: [
                      TextButton(onPressed: () => Get.back(), child: Text("OK")),
                    ],
                  ));
                  final file = await FilePickerCross.importFromStorage(type: FileTypeCross.any);
                  final confirmation = await Get.dialog(AlertDialog(
                    title: Text("Are you sure you want to import this?"),
                    content: Text("Importing this WILL clear your entire journal! Make sure you've performed a backup, and make sure you are importing the correct file.\n"
                    "No checks are done to make sure you're importing valid data, so you have to do it yourself!"),
                    actions: [
                      TextButton(onPressed: () => Get.back(result: false), child: Text("STAY SAFE")),
                      TextButton(onPressed: () => Get.back(result: true), child: Text("YES", style: TextStyle(color: Colors.red))),
                    ],
                  ));
                  if (confirmation == false) return;
                  await File(platformStorageDir.absolute.path + "/dreamjournal.json").writeAsBytes(file.toUint8List());
                  await Get.dialog(AlertDialog(
                    title: Text("Immediate restart required"),
                    content: Text("The app will now restart to finish applying this change."),
                    actions: [
                      TextButton(onPressed: () => exit(0), child: Text("OK")),
                    ],
                  ));
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