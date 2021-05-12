import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart' as Settings;

class SettingsRoot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Settings.SettingsScreen(
      title: "Settings",
      children: [
        Settings.SwitchSettingsTile(
          title: "AMOLED Dark Mode",
          settingKey: "amoled-dark",
          icon: Icon(Icons.nights_stay),
        ),
        // if (!GetPlatform.isIOS) Settings.SettingsTile(
        //   title: "Log Storage Filename",
        //   subtitle: "This will NOT move the file! ALL YOUR DATA WILL BE LOST!",
        //   icon: Icon(Icons.folder),
        // )
        Settings.RadioSettingsTile(
          settingKey: "datetime-format",
          title: "Date format",
          icon: Icon(Icons.date_range),
          defaultKey: "american",
          values: {
            "american": "Wed May 12 2021  2:34 pm",
            "european": "5 Nov 2019 19:42"
          },
        )
      ]
    );
  }
}