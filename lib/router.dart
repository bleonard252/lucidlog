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
  GetPage(name: "/dreams/new", middlewares: [OnboardingMiddleware()], page: () => DreamEditor(mode: DreamEditMode.create)),
  GetPage(name: "/dreams/tag", middlewares: [OnboardingMiddleware()], page: () => DreamEditor(mode: DreamEditMode.tag)),
  GetPage(name: "/dreams/edit", middlewares: [OnboardingMiddleware()], page: () => DreamEditor(mode: DreamEditMode.edit, dream: Get.arguments as DreamRecord)),
  GetPage(name: "/dreams/complete", middlewares: [OnboardingMiddleware()], page: () => DreamEditor(mode: DreamEditMode.complete, dream: Get.arguments as DreamRecord)),
  GetPage(name: "/dreams/details", middlewares: [OnboardingMiddleware()], page: () => MiddleSegment(DreamDetails(Get.arguments as DreamRecord)), transition: Transition.fadeIn, opaque: false),
  GetPage(name: "/realms/list", middlewares: [OnboardingMiddleware()], page: () => RealmListScreen()),
  GetPage(name: "/realms/new", middlewares: [OnboardingMiddleware()], page: () => RealmEditor(mode: RealmEditMode.create)),
  GetPage(name: "/realms/edit", middlewares: [OnboardingMiddleware()], page: () => RealmEditor(realm: Get.arguments as RealmRecord, mode: RealmEditMode.edit)),
  GetPage(name: "/realms/details", middlewares: [OnboardingMiddleware()], page: () => MiddleSegment(RealmDetails(Get.arguments as RealmRecord)), transition: Transition.fadeIn, opaque: false),
  GetPage(name: "/search", middlewares: [OnboardingMiddleware()], page: () => SearchScreen()),
  GetPage(name: "/stats", middlewares: [OnboardingMiddleware()], page: () => MiddleSegment(StatisticsScreen()), transition: Transition.fadeIn, opaque: false),
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

int _middleSegmentsActive = 0;

class MiddleSegment extends StatefulWidget {
  final Widget child;
  const MiddleSegment(this.child, { Key? key }) : super(key: key);

  @override
  _MiddleSegmentState createState() => _MiddleSegmentState();
}

class _MiddleSegmentState extends State<MiddleSegment> {
  @override
  void initState() {
    _middleSegmentsActive++;
    super.initState();
  }
  @override
  void dispose() {
    _middleSegmentsActive--;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(_middleSegmentsActive);
    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            alignment: Alignment.center,
            color: _middleSegmentsActive == 1 ? Colors.black54.withOpacity(0.7) : Colors.transparent
          ),
        ),
        Container(
          child: widget.child,
          width: 640,
          alignment: Alignment.topCenter,
        ),
      ],
    );
  }
}