import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:date_time_format/date_time_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:journal/db/dream.dart';
import 'package:journal/db/realm.dart';
import 'package:journal/migrations/databasev6.dart';
import 'package:journal/router.dart';
import 'package:journal/versions.dart';
import 'package:journal/views/optional_features.dart';
import 'package:journal/widgets/empty_state.dart';
import 'package:journal/widgets/preflight.dart';
import 'package:mdi/mdi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

late final Directory platformStorageDir;
late final File databaseFile;
late final List database;
late final File realmDatabaseFile;
late final List realmDatabase;
late final SharedPreferences sharedPreferences;
late final FlutterLocalNotificationsPlugin? notificationsPlugin;
late final bool? canUseNotifications;
late List<DreamRecord> dreamList;
late List<RealmRecord> realmList;
bool isRealmDatabaseLoaded = false;
int profileNumber = 1;
List<String> migrationNotices = [];

/// The version that the app is running on. This should match up with the current version number,
/// and is shown in About to verify it.
/// It should be checked during migration to determine the effective version
/// of the app's database and settings,
/// and to confirm that no further migrations need to be done.
String? get appVersion => sharedPreferences.getString("last-version");
Version? get appver => Version(appVersion ?? "999");

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sharedPreferences = await SharedPreferences.getInstance();
  if (!sharedPreferences.containsKey("amoled-dark")) sharedPreferences.setBool("amoled-dark", false);
  if (!sharedPreferences.containsKey("datetime-format")) sharedPreferences.setString("datetime-format", DateTimeFormats.commonLogFormat);
  if (sharedPreferences.getString("datetime-format") == "american") sharedPreferences.setString("datetime-format", DateTimeFormats.commonLogFormat);
  //final _androidStorageOne = Directory("/storage/emulated/0/Documents");
  profileNumber = sharedPreferences.getInt("profile") ?? 1;
  var _platformStorageDir = GetPlatform.isAndroid ? ((await getExternalStorageDirectories(type: StorageDirectory.documents)) ?? [])[0]
    : GetPlatform.isLinux ? await getApplicationDocumentsDirectory()
    : GetPlatform.isIOS ? await getApplicationDocumentsDirectory()
    : GetPlatform.isWindows ? await getApplicationDocumentsDirectory()
    : await getApplicationSupportDirectory();
  final _tempPSD = Directory(_platformStorageDir.absolute.path + "/lldj-temp-profile/");
  if (await _tempPSD.exists()) _tempPSD.delete(recursive: true);
  if (profileNumber == 1) platformStorageDir = Directory(_platformStorageDir.absolute.path);
  else if (profileNumber == 0) platformStorageDir = _tempPSD;
  else platformStorageDir = Directory(_platformStorageDir.absolute.path + "/lldj-profile-$profileNumber/");
  /// Migrations which have been removed should be added here.
  const unsupportedVersions = ["4"];
  if (unsupportedVersions.contains(appVersion)) {
    return runApp(PreflightScreen(
      child: EmptyState(
        icon: Icon(Mdi.alertOctagon),
        text: Text("The app's previous version is too old.\n"
        "You will need to uninstall the app, then try again."),
        preflight: true,
      )
    ));
  }
  if (appVersion == "5") {
    print("running database migration: 5 -> 6");
    final migration = databaseMigrationVersion6();
    runApp(PreflightScreen(
      child: EmptyState(
        icon: Icon(Mdi.uploadMultiple),
        text: Text("The database is being upgraded. Please wait."),
        preflight: true,
      )
    ));
    await migration;
    sharedPreferences.setString("last-version", "6");
  }
  if (appVersion == "6" || (appVersion?.startsWith("7 beta")??false)) {
    print("running database migration: 6 -> 7");
    runApp(PreflightScreen(
      child: EmptyState(
        icon: Icon(Mdi.tagMultiple),
        text: Text("An optional feature is being checked for you. Please wait."),
        preflight: true,
      )
    ));
    final databaseFile = File(platformStorageDir.absolute.path + "/dreamjournal.json");
    final List database = jsonDecode(await databaseFile.readAsString());
    final hasUsedTags = database.any((element) => element["tags"] is List) 
    || database.any((element) => element["incomplete"] is bool && element["incomplete"] == true);
    sharedPreferences.setBool("opt-tags", hasUsedTags);
    sharedPreferences.setString("last-version", "7");
    migrationNotices.add("Tags are now an optional feature. However, you've used them before, so it's been turned on for you.");
  }
  if (appVersion != "" && (appver ?? Version("999")) < Version("8")) migrationNotices.add("The editor has been updated! The creating and tagging process should still be familiar.");
  else if (appVersion == "8 beta 1" && OptionalFeatures.realms) migrationNotices.add("The editor has been updated! You can now create and edit PRs with the new editor, too.");
  else if (appVersion == "8 beta 1") migrationNotices.add("The editor has been updated!");
  sharedPreferences.setString("last-version", "9 beta 1");
  databaseFile = File(platformStorageDir.absolute.path + "/dreamjournal.json");
  if (!await databaseFile.exists()) {
    await databaseFile.create(recursive: true);
    await databaseFile.writeAsString("[]");
  }
  realmDatabaseFile = File(platformStorageDir.absolute.path + "/lldj-realms.json");
  if (!await realmDatabaseFile.exists()) {
    await realmDatabaseFile.create(recursive: true);
    await realmDatabaseFile.writeAsString("[]");
    // return runApp(PreflightScreen(
    //   child: EmptyState(
    //     icon: Icon(Mdi.listStatus),
    //     text: Text("The PR list should have already been created if the Persistent Realms optional feature is on."),
    //     preflight: true,
    //   )
    // ));
  }
  if (sharedPreferences.getBool("onboarding-completed") ?? false) {
    database = jsonDecode(await databaseFile.readAsString()) as dynamic; //sharedPreferences.getString("storage-path")!));
    realmDatabase = jsonDecode(await realmDatabaseFile.readAsString()) as dynamic;
    isRealmDatabaseLoaded = true;
  }
  final _commentsFolder = Directory(platformStorageDir.absolute.path + "/lldj-comments/");
  if (!await _commentsFolder.exists()) await _commentsFolder.create();
  final _plotlinesFolder = Directory(platformStorageDir.absolute.path + "/lldj-plotlines/");
  if (!await _plotlinesFolder.exists()) await _plotlinesFolder.create();
  final _realmsFolder = Directory(platformStorageDir.absolute.path + "/lldj-realms/");
  if (!await _realmsFolder.exists()) await _realmsFolder.create();
  try {
    notificationsPlugin = FlutterLocalNotificationsPlugin();
    canUseNotifications = (await notificationsPlugin!.initialize(InitializationSettings(
      android: AndroidInitializationSettings("@drawable/ic_notification")
    )) ?? false) && (Platform.isAndroid || Platform.isIOS);
    if (canUseNotifications == false) print("${Platform.operatingSystem} does not support notifications");
  } catch(e) {print("${Platform.operatingSystem} does not support notifications");}
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final bool permissionDenied;
  MyApp({this.permissionDenied = false});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var _theme = ({Color? surfaceColor, Color? cardColor}) => ThemeData.dark().copyWith(
      canvasColor: surfaceColor,
      scaffoldBackgroundColor: surfaceColor,
      cardColor: cardColor,
      primaryColor: Colors.purple,
      //accentColor: Colors.amber,
      colorScheme: ColorScheme.dark(
        primary: Colors.purple,
        secondary: Colors.amber,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.amber
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        shadowColor: Colors.purple
      ),
      bottomAppBarTheme: BottomAppBarTheme(
        color: Colors.grey[900],
        elevation: 2.0
      ),
      bannerTheme: MaterialBannerThemeData(
        backgroundColor: Colors.purple[900]!.withAlpha(36)
      ),
      buttonTheme: ButtonThemeData(
        padding: EdgeInsets.all(16.0),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.purple,
          accentColor: Colors.amber
        ),
        buttonColor: Colors.purple
      ),
      inputDecorationTheme: InputDecorationTheme(
        focusColor: Colors.purple,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return Colors.amber;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return Colors.amberAccent;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return Colors.amber;
        }),
      )
    );
    return GetMaterialApp(
      title: 'Dream Journal',
      theme: _theme(
        surfaceColor: Color.fromARGB(255, 0, 0, 20),
        cardColor: Color.fromARGB(255, 7, 0, 37),
      ),
      darkTheme: _theme(
        surfaceColor: Colors.black,
        cardColor: Colors.grey[900]!
      ),
      themeMode: sharedPreferences.getBool("amoled-dark") ?? false 
        ? ThemeMode.dark : ThemeMode.light,
      initialRoute: "/",
      getPages: [
        if (permissionDenied) GetPage(name: "/", page: () => EmptyState(
          icon: Icon(Icons.sd_storage_outlined),
          text: Text("Storage permission was denied."),
        )) else ...router
      ],
    );
  }
}

final purpleGradient = LinearGradient(
  colors: [Colors.purple, Colors.deepPurple], 
  transform: GradientRotation(1.5*pi)
);
final redGradient = LinearGradient(
  colors: [Colors.red.shade900, Colors.red], 
  transform: GradientRotation(1.5*pi)
);
final goldGradient = LinearGradient(
  colors: [Colors.amber, Colors.orange], 
  transform: GradientRotation(1.5*pi)
);
final blueGreenGradient = LinearGradient(
  colors: [Colors.blue, Colors.green], 
  transform: GradientRotation(1.5*pi)
);