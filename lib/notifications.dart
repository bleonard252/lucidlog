import 'package:flutter/material.dart' show Colors;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:journal/main.dart';

abstract class RealityCheck {
  static Future<void> schedule() async {
    if (canUseNotifications == false) return;
    return await notificationsPlugin?.show(1984, "Reality check!", "Are you dreaming?", NotificationDetails(
      android: AndroidNotificationDetails(
        "realitycheck", "Reality Check", "", sound: RawResourceAndroidNotificationSound("@raw/reality_check"),
        showWhen: false, color: Colors.purple
      )
    ));
  }
}