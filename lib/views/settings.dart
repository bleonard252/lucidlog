import 'package:flutter/material.dart';
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
          icon: Icon(Icons.nights_stay)
        )
      ]
    );
  }
}