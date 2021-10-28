import "package:flutter/material.dart";
import 'package:journal/main.dart';
import 'package:journal/views/methods.dart';
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
          title: "Remember Techniques",
          settingKey: "opt-methods",
          defaultValue: false,
          subtitle: "Adds a list in the editor for these set techniques.",
          //screen: MethodsSettingsScreen()
        ),
        Settings.SwitchSettingsTile(
          title: "Counters",
          settingKey: "opt-counters",
          defaultValue: false,
          subtitle: "Add counters to the dream detail screen. This will count your dreams, lucids, and in coordination with WILD Distinction, WILDs."
          " Also adds the Statistics screen, accessible from Search.",
        ),
        Settings.SwitchSettingsTile(
          title: "Group by Night",
          settingKey: "opt-nightly",
          defaultValue: false,
          subtitle: "Adds a header to the most recent dream of each night, showing what night you had some dreams on. This is useful when you have high recall.",
        ),
        Settings.SwitchSettingsTile(
          title: "Comments",
          subtitle: "Add comments to the details page for a dream.",
          settingKey: "opt-comments",
          defaultValue: false,
        ),
        Settings.RadioSettingsTile(
          title: "Plotlines",
          subtitle: "Have multiple distinct scenes for each of your dreams, with its own subtitle and body.",
          settingKey: "opt-plotlines",
          expandable: true,
          initiallyExpanded: false,
          values: {
            "expandable": "Use expanding sections",
            "slider": "Use a slider",
            "none": "Off"
          },
          defaultKey: "none",
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
  /// for dreams that use WILD as its only technique.
  static get rememberMethods => sharedPreferences.getBool("opt-methods") ?? false;
  /// Calculate counters for every dream on its details screen.
  /// This will help you identify dreams by numbers, if you want,
  /// and identify lucid dream streaks.
  /// These counters include:
  /// * Dream number (Dream #)
  /// * Nights with lucid dreams in a row (#-night Lucid Streak)
  /// * Recorded dreams that are lucid (#-dream Lucid Streak)
  /// * Lucid dream number (LD #)
  /// * Non-lucid dream number (NLD #)
  static get counters => sharedPreferences.getBool("opt-counters") ?? false;
  /// Whether to group dreams by night in the main list.
  static get nightly => sharedPreferences.getBool("opt-nightly") ?? false;
  /// Whether to show comments in the dream creation view.
  /// Unlike other optional features, this one actually hides
  /// existing results as it has to load an additional file to
  /// show them.
  static get comments => sharedPreferences.getBool("opt-comments") ?? false;
  /// How to show the plotlines feature. A prompt will display on dreams that 
  /// use this, telling you to enable plotlines, if you have this set to
  /// [PlotlineTypes.NONE].
  static PlotlineTypes get plotlines => 
  sharedPreferences.getString("opt-plotlines") == "expandable" ? PlotlineTypes.EXPANDABLE
  : sharedPreferences.getString("opt-plotlines") == "slider" ? PlotlineTypes.SLIDER
  : PlotlineTypes.NONE;
}

enum PlotlineTypes {
  EXPANDABLE,
  SLIDER,
  NONE
}