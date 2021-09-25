import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EmptyState extends StatelessWidget {
  final Widget? icon;
  final Widget? text;
  final bool preflight;

  EmptyState({
    Key? key,
    this.icon,
    this.text,
    this.preflight = false
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: Get.textTheme.bodyText2!.copyWith(
        color: preflight ? Colors.grey.shade600 : Get.theme.disabledColor,
      ),
      textAlign: TextAlign.center,
      child: Theme(
        data: Get.theme.copyWith(
          iconTheme: Get.theme.iconTheme.copyWith(
            color: preflight ? Colors.grey.shade600 : Get.theme.disabledColor,
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