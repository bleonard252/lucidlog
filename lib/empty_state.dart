import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EmptyState extends StatelessWidget {
  final Widget? icon;
  final Widget? text;

  EmptyState({
    Key? key,
    this.icon,
    this.text
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: Get.textTheme.bodyText2!.copyWith(
        color: Get.theme.disabledColor,
      ),
      textAlign: TextAlign.center,
      child: Theme(
        data: Get.theme.copyWith(
          iconTheme: Get.theme.iconTheme.copyWith(
            color: Get.theme.disabledColor,
            size: 96
          )
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) icon!,
            if (text != null) text!
          ],
        ),
      ),
    );
  }
}