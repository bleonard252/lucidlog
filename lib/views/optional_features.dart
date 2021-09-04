import "package:flutter/material.dart";
import 'package:journal/main.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart' as Settings;

class OptionalFeaturesSettingsScreen extends StatelessWidget {
  const OptionalFeaturesSettingsScreen({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Settings.SettingsScreen(
      title: "Optional features",
      children: [
        Settings.SwitchSettingsTile(
          title: "WILD Distinction",
          settingKey: "opt-wild",
          defaultValue: false,
          subtitle: "Gives WILDs special markings, including colors and an icon.",
        ),
        Settings.SwitchSettingsTile(
          title: "Remember Methods",
          settingKey: "opt-methods",
          defaultValue: false,
          subtitle: "Show a list in the editor for your set techniques. This is also controlled from the toggle on the Methods page.",
        )
      ]
    );
  }
}

abstract class OptionalFeatures {
  /// WILD Distinction, which was moved to an optional feature.
  /// This is used to enable certain WILD-related features
  /// that make WILDs stand out from other lucids by giving
  /// them a distinct color and icon.
  static get wildDistinction => sharedPreferences.getBool("opt-wild") ?? false;
  /// Shows the screen to mark techniques.
  /// If this is off and `wildDistinction` is on, hide the method list
  /// for dreams that use MILD as its only technique.
  static get rememberMethods => sharedPreferences.getBool("opt-methods") ?? false;
}