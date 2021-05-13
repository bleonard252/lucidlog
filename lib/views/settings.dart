import 'package:date_time_format/date_time_format.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal/main.dart';
import 'package:journal/notifications.dart';
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
            AmericanDateTimeFormats.abbrDayOfWeekAbbr: "Tue Nov 5, 2019 7:42 pm",
            EuropeanDateTimeFormats.abbrDayOfWeekAbbr: "Tue 5 Nov 2019 19:42",
            AmericanDateTimeFormats.short: "11/05/2019 7:42 pm",
            EuropeanDateTimeFormats.short: "05/11/2019 19:42"
          },
        ),
        if (canUseNotifications == true) Settings.SettingsTileGroup(
          title: "Notifications",
          children: [
            ListTile(
              title: Text("Test Notification"),
              leading: Icon(Icons.notifications_active),
              onTap: () => RealityCheck.schedule(),
            )
          ],
        )
      ]
    );
  }
}