import 'dart:io';
import 'dart:math';

import 'package:date_time_format/date_time_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:journal/db/dream.dart';
import 'package:journal/views/about.dart';
import 'package:journal/widgets/empty_state.dart';
import 'package:journal/views/details.dart';
import 'package:journal/views/editor.dart';
import 'package:journal/views/list.dart';
import 'package:journal/views/onboarding.dart';
import 'package:journal/views/search.dart';
import 'package:journal/views/settings.dart';
import 'package:objectdb/objectdb.dart';
// ignore: implementation_imports
import 'package:objectdb/src/objectdb_storage_filesystem.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

late final Directory platformStorageDir;
late final ObjectDB database;
late final SharedPreferences sharedPreferences;
late final FlutterLocalNotificationsPlugin? notificationsPlugin;
late final bool? canUseNotifications;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sharedPreferences = await SharedPreferences.getInstance();
  if (!sharedPreferences.containsKey("amoled-dark")) sharedPreferences.setBool("amoled-dark", false);
  if (!sharedPreferences.containsKey("datetime-format")) sharedPreferences.setString("datetime-format", DateTimeFormats.commonLogFormat);
  if (sharedPreferences.getString("datetime-format") == "american") sharedPreferences.setString("datetime-format", DateTimeFormats.commonLogFormat);
  //final _androidStorageOne = Directory("/storage/emulated/0/Documents");
  platformStorageDir = GetPlatform.isAndroid ? ((await getExternalStorageDirectories(type: StorageDirectory.documents)) ?? [])[0]
    : GetPlatform.isLinux ? await getApplicationDocumentsDirectory()
    : GetPlatform.isIOS ? await getApplicationDocumentsDirectory()
    : GetPlatform.isWindows ? await getApplicationDocumentsDirectory()
    : await getApplicationSupportDirectory();
  sharedPreferences.setString("last-version", "5");
  // TODO: perform migrations depending on version changes
  if (sharedPreferences.getBool("onboarding-completed") ?? false) {
    // platformStorageDir = GetPlatform.isIOS ? await getApplicationDocumentsDirectory()
    // : Directory(sharedPreferences.getString("storage-path") ?? "");
    // if ((Platform.isAndroid || Platform.isIOS) && !(await Permission.storage.isGranted)) {
    //   var _result = await Permission.storage.request();
    //   if (_result != PermissionStatus.granted) return runApp(MyApp(permissionDenied: true));
    // }
    database = ObjectDB(FileSystemStorage(GetPlatform.isIOS ? (await getApplicationDocumentsDirectory()).absolute.path + "/dreamjournal.db"
    : platformStorageDir.absolute.path + "/dreamjournal.db")); //sharedPreferences.getString("storage-path")!));
  }
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
      accentColor: Colors.amber,
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.amber
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        shadowColor: Colors.purple
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
        )) else ...[
          GetPage(name: "/", middlewares: [OnboardingMiddleware()], page: () => DreamListScreen()),
          GetPage(name: "/settings", page: () => SettingsRoot()),
          GetPage(name: "/new", middlewares: [OnboardingMiddleware()], page: () => DreamEdit(mode: DreamEditMode.create)),
          GetPage(name: "/tag", middlewares: [OnboardingMiddleware()], page: () => DreamEdit(mode: DreamEditMode.tag)),
          GetPage(name: "/edit", middlewares: [OnboardingMiddleware()], page: () => DreamEdit(mode: DreamEditMode.edit, dream: Get.arguments as DreamRecord)),
          GetPage(name: "/complete", middlewares: [OnboardingMiddleware()], page: () => DreamEdit(mode: DreamEditMode.complete, dream: Get.arguments as DreamRecord)),
          GetPage(name: "/details", middlewares: [OnboardingMiddleware()], page: () => middleSegment(DreamDetails(Get.arguments as DreamRecord)), transition: Transition.fadeIn, opaque: false),
          GetPage(name: "/search", middlewares: [OnboardingMiddleware()], page: () => SearchScreen()),
          GetPage(name: "/onboarding", page: () => OnboardingScreen()),
          GetPage(name: "/about", page: () => AboutScreen()),
        ]
      ],
    );
  }
}

class OnboardingMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!(sharedPreferences.getBool("onboarding-completed") ?? false)) return RouteSettings(name: '/onboarding');
    else return null;
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
final redGradient = LinearGradient(
  colors: [Colors.red.shade900, Colors.red], 
  transform: GradientRotation(1.5*pi)
);
final goldGradient = LinearGradient(
  colors: [Colors.amber, Colors.orange], 
  transform: GradientRotation(1.5*pi)
);