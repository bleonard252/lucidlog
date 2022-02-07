import 'package:file/memory.dart';
import 'package:flutter/material.dart';
import 'package:journal/db/dream.dart';
import 'package:journal/main.dart';
import 'package:lldj_share_viewer/home.dart';

void main() {
  sharedPreferences.setString("opt-plotlines", "expandable");
  runApp(const MyApp());
}

var temporaryProfileFS = MemoryFileSystem();
var realmDreamList = <DreamRecord>[];

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LucidLog Dream Journal',
      theme: ThemeData.dark().copyWith(
        canvasColor: Color.fromARGB(255, 0, 0, 20),
        scaffoldBackgroundColor: Color.fromARGB(255, 0, 0, 20),
        cardColor: Color.fromARGB(255, 7, 0, 37),
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
          backgroundColor: Color.fromARGB(255, 0, 0, 20),
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
      ),
      home: const ShareViewerHomeScreen(),
    );
  }
}

