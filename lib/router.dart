import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal/db/realm.dart';
import 'package:journal/main.dart';
import 'package:journal/views/about.dart';
import 'package:journal/views/details.dart';
import 'package:journal/views/editor.dart';
import 'package:journal/views/list.dart';
import 'package:journal/views/onboarding.dart';
import 'package:journal/views/realms/details.dart';
import 'package:journal/views/realms/editor.dart';
import 'package:journal/views/realms/list.dart';
import 'package:journal/views/search.dart';
import 'package:journal/views/settings.dart';
import 'package:journal/views/statistics.dart';

import 'db/dream.dart';

final router = [
  GetPage(name: "/", middlewares: [OnboardingMiddleware()], page: () => DreamListScreen()),
  GetPage(name: "/settings", page: () => SettingsRoot()),
  GetPage(name: "/dreams/new", middlewares: [OnboardingMiddleware()], page: () => DreamEdit(mode: DreamEditMode.create)),
  GetPage(name: "/dreams/tag", middlewares: [OnboardingMiddleware()], page: () => DreamEdit(mode: DreamEditMode.tag)),
  GetPage(name: "/dreams/edit", middlewares: [OnboardingMiddleware()], page: () => DreamEdit(mode: DreamEditMode.edit, dream: Get.arguments as DreamRecord)),
  GetPage(name: "/dreams/complete", middlewares: [OnboardingMiddleware()], page: () => DreamEdit(mode: DreamEditMode.complete, dream: Get.arguments as DreamRecord)),
  GetPage(name: "/dreams/details", middlewares: [OnboardingMiddleware()], page: () => middleSegment(DreamDetails(Get.arguments as DreamRecord)), transition: Transition.fadeIn, opaque: false),
  GetPage(name: "/realms/list", middlewares: [OnboardingMiddleware()], page: () => RealmListScreen()),
  GetPage(name: "/realms/new", middlewares: [OnboardingMiddleware()], page: () => RealmEdit(mode: RealmEditMode.create)),
  GetPage(name: "/realms/edit", middlewares: [OnboardingMiddleware()], page: () => RealmEdit(realm: Get.arguments as RealmRecord, mode: RealmEditMode.edit)),
  GetPage(name: "/realms/details", middlewares: [OnboardingMiddleware()], page: () => middleSegment(RealmDetails(Get.arguments as RealmRecord)), transition: Transition.fadeIn, opaque: false),
  GetPage(name: "/search", middlewares: [OnboardingMiddleware()], page: () => SearchScreen()),
  GetPage(name: "/stats", middlewares: [OnboardingMiddleware()], page: () => middleSegment(StatisticsScreen()), transition: Transition.fadeIn, opaque: false),
  GetPage(name: "/onboarding", page: () => OnboardingScreen()),
  GetPage(name: "/about", page: () => AboutScreen()),
];


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
        width: 640,
        alignment: Alignment.topCenter,
      ),
    ],
  );
}