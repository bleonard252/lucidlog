import 'dart:io';

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

late final Directory platformStorageDir;
late final ObjectDB database;

void main() async {
  platformStorageDir = GetPlatform.isAndroid ? await getApplicationSupportDirectory()
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
      title: 'Flutter Demo',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.purple,
        canvasColor: Color.fromARGB(255, 0, 0, 20),
        scaffoldBackgroundColor: Color.fromARGB(255, 0, 0, 20),
        accentColor: Colors.amber,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.amber
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.purple,
        canvasColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        accentColor: Colors.amber,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.amber
        ),
      ),
      initialRoute: "/",
      getPages: [
        GetPage(name: "/", page: () => DreamListScreen()),
        GetPage(name: "/settings", page: () => SettingsRoot()),
        GetPage(name: "/new", page: () => DreamEdit(mode: DreamEditMode.create)),
        GetPage(name: "/details", page: () => DreamDetails(Get.arguments as DreamRecord), transition: Transition.downToUp, opaque: false)
      ],
    );
  }
}
