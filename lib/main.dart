import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal/db/dream.dart';
import 'package:journal/views/details.dart';
import 'package:journal/views/editor.dart';
import 'package:journal/views/list.dart';
import 'package:journal/views/settings.dart';
import 'package:objectdb/objectdb.dart';
// ignore: implementation_imports
import 'package:objectdb/src/objectdb_storage_filesystem.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

late final Directory platformStorageDir;
late final ObjectDB database;
late final SharedPreferences sharedPreferences;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sharedPreferences = await SharedPreferences.getInstance();
  if (!sharedPreferences.containsKey("amoled-dark")) sharedPreferences.setBool("amoled-dark", false);
  if (!sharedPreferences.containsKey("datetime-format")) sharedPreferences.setString("datetime-format", "american");
  final _androidStorageOne = Directory("/storage/emulated/0/Documents");
  platformStorageDir = GetPlatform.isAndroid ? _androidStorageOne.existsSync() ? _androidStorageOne
      : _androidStorageOne //TODO: more paths!
    : GetPlatform.isLinux ? await getApplicationDocumentsDirectory()
    : GetPlatform.isIOS ? await getApplicationDocumentsDirectory()
    : await getApplicationSupportDirectory().catchError((_) => Future.value(Directory("")));
  database = ObjectDB(FileSystemStorage(platformStorageDir.absolute.path + "/dreamjournal.db"));
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Dream Journal',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.purple,
        canvasColor: Color.fromARGB(255, 0, 0, 20),
        scaffoldBackgroundColor: Color.fromARGB(255, 0, 0, 20),
        accentColor: Colors.amber,
        cardColor: Color.fromARGB(255, 7, 0, 37),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.amber
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.purple,
        canvasColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        accentColor: Colors.amber,
        cardColor: Colors.grey[900],
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.amber
        ),
      ),
      themeMode: sharedPreferences.getBool("amoled-dark") ?? false 
        ? ThemeMode.dark : ThemeMode.light,
      initialRoute: "/",
      getPages: [
        GetPage(name: "/", page: () => DreamListScreen()),
        GetPage(name: "/settings", page: () => SettingsRoot()),
        GetPage(name: "/new", page: () => DreamEdit(mode: DreamEditMode.create)),
        GetPage(name: "/edit", page: () => DreamEdit(mode: DreamEditMode.edit, dream: Get.arguments as DreamRecord)),
        GetPage(name: "/details", page: () => middleSegment(DreamDetails(Get.arguments as DreamRecord)), transition: Transition.fadeIn, opaque: false)
      ],
    );
  }
}

Widget middleSegment(Widget child) {
  return Stack(
    alignment: Alignment.center,
    children: [
      Container(
        alignment: Alignment.center,
        color: Colors.black54.withOpacity(0.7),
      ),
      Container(
        child: child,
        width: 720,
        alignment: Alignment.topCenter,
      ),
    ],
  );
}

final purpleGradient = LinearGradient(
  colors: [Colors.purple, Colors.deepPurple], 
  transform: GradientRotation(1.5*pi)
);
final goldGradient = LinearGradient(
  colors: [Colors.amber, Colors.orange], 
  transform: GradientRotation(1.5*pi)
);