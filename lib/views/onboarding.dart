import 'dart:convert';
import 'package:date_time_format/date_time_format.dart';
import "package:flutter/material.dart";
import 'package:get/get.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:journal/main.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart' as Settings;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({ Key? key }) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool isNextEnabled = true;
  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      globalBackgroundColor: Get.theme.canvasColor,
      dotsDecorator: DotsDecorator(activeColor: Get.theme.colorScheme.secondary),
      color: Get.theme.colorScheme.secondary,
      pages: [
        PageViewModel(
          title: "",
          bodyWidget: Center(
            child: Text("Welcome to\nDream Journal", style: Get.textTheme.headline4, textAlign: TextAlign.center),
          )
        ),
        PageViewModel(
          title: "Set date and time format",
          bodyWidget: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: (_) {
              if (sharedPreferences.getString("datetime-format") != null) {
                setState(() => isNextEnabled = true);
              }
            },
            child: Settings.RadioSettingsTile(
              settingKey: "datetime-format",
              title: "Date format",
              icon: Icon(Icons.date_range),
              defaultKey: AmericanDateTimeFormats.abbrDayOfWeekAbbr,
              values: {
                AmericanDateTimeFormats.abbrDayOfWeekAbbr: "Tue Nov 5, 2019 7:42 pm",
                EuropeanDateTimeFormats.abbrDayOfWeekAbbr: "Tue 5 Nov 2019 19:42",
                AmericanDateTimeFormats.short: "11/05/2019 7:42 pm",
                EuropeanDateTimeFormats.short: "05/11/2019 19:42"
              },
            ),
          ),
        ),
        // if (GetPlatform.isDesktop) PageViewModel(
        //   title: "Set storage location",
        //   bodyWidget: Center(
        //     child: Column(
        //       children: [
        //         Text("The file will be called dreamjournal.db\nand it will be saved in the\nfolder you select."),
        //         Padding(
        //           padding: const EdgeInsets.all(8.0),
        //           child: ElevatedButton(
        //             onPressed: () async {
        //               late final String? result;
        //               try {
        //                 result = (await FilePickerCross(File.fromUri(Uri.parse(sharedPreferences.getString("storage-path") ?? "")).readAsBytesSync()).exportToStorage(fileName: "dreamjournal.db"));
        //               } on FileSystemException {
        //                 result = (await FilePickerCross(Uint8List(0)).exportToStorage(fileName: "dreamjournal.db"));
        //               } on FormatException {
        //                 result = (await FilePickerCross(Uint8List(0)).exportToStorage(fileName: "dreamjournal.db"));
        //               }
        //               //: (await FilePicker.platform.getDirectoryPath()) ?? "/" + "/dreamjournal.db";
        //               if (result == null) return;
        //               final exists = await Directory(result).exists();
        //               if (!exists) return;
        //               if (!(await Directory(result).stat()).modeString().replaceAll(RegExp('\(.*?\)'), "").startsWith("rw")) return;
        //               if (result == "/" || result == "//dreamjournal.db") return;
        //               await sharedPreferences.setString("storage-path", result);
        //               setState(() => isNextEnabled = true);
        //             },
        //             child: Text("Browse for directory")
        //           ),
        //         ),
        //       ],
        //     ),
        //   )
        // ),
        PageViewModel(
          title: "",
          bodyWidget: Center(
            child: Text("You have completed setup!", style: Get.textTheme.bodyText2, textAlign: TextAlign.center),
          )
        ),
      ],
      freeze: !isNextEnabled,
      showNextButton: isNextEnabled,
      showDoneButton: isNextEnabled,
      onChange: (page) {
        if (page == 1 || page == 2) {
          isNextEnabled = false;
        }
      },
      next: Text("NEXT"),
      done: Text("DONE"),
      onDone: () async {
        // This is a late final that **isn't used**
        // at the time the onboarding is shown.
        sharedPreferences.setBool("onboarding-completed", true);
        // platformStorageDir = GetPlatform.isIOS ? await getApplicationDocumentsDirectory()
        // : Directory(sharedPreferences.getString("storage-path") ?? "");
        // if ((Platform.isAndroid || Platform.isIOS) && !(await Permission.storage.isGranted)) {
        //   var _result = await Permission.storage.request();
        //   if (_result != PermissionStatus.granted) return runApp(MyApp(permissionDenied: true));
        // }
        //ignore: assignment_to_final
        database = jsonDecode(await databaseFile.readAsString()) as dynamic;
        realmDatabase = jsonDecode(await realmDatabaseFile.readAsString()) as dynamic;
        isRealmDatabaseLoaded = true;
        Get.offAllNamed("/");
      },
    );
  }
}