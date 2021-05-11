import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal/db/dream.dart';
import 'package:journal/main.dart';

class DreamDetails extends StatelessWidget {
  final DreamRecord dream;

  DreamDetails(this.dream, {Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Get.theme.canvasColor,
      child: Container(
        width: 640,
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back,
                color: Get.theme.colorScheme.onSurface
              ),
              onPressed: () => Get.back(),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => Get.offAndToNamed("/edit", arguments: dream)
              )
            ],
            backgroundColor: Get.theme.canvasColor,
            elevation: 0,
          ),
          Row(children: [
            Container(
              padding: EdgeInsets.only(left: 24),
              child: Container(
                width: 56, height: 56,
                //radius: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(32)),
                  gradient: purpleGradient
                ),
                //backgroundColor: dream.lucid ? Get.theme.primaryColor : Get.theme.disabledColor,
                //foregroundColor: Get.textTheme.button!.color,
                child: dream.lucid ? Icon(Icons.cloud) : Icon(Icons.cloud_outlined)
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(24),
                child: Text(
                  dream.title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: null,
                  style: Get.textTheme.headline4
                )
              ),
            ),
          ],),
          Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              width: 999999999,
              child: Material(
                elevation: 2,
                type: MaterialType.card,
                color: Get.theme.cardColor,
                borderRadius: BorderRadius.all(Radius.circular(0)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("Summary", 
                      style: Get.textTheme.subtitle1?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(dream.body)//Text(room.topic, style: Get.textTheme.bodyText2),
                  )
                ])
              )
            ),
          ]
        ))
      )
    );
  }
}