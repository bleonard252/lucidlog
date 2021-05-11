import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal/db/dream.dart';

class DreamDetails extends StatelessWidget {
  final DreamRecord dream;

  DreamDetails(this.dream, {Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).canvasColor,
      child: Container(
        width: 640,
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface
              ),
              onPressed: () => Navigator.of(context).pop(null),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => Get.offAndToNamed("/edit", arguments: dream)
              )
            ],
            backgroundColor: Theme.of(context).canvasColor,
            elevation: 0,
          ),
          Row(children: [
            Container(
              padding: EdgeInsets.only(left: 24),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: dream.lucid ? Get.theme.primaryColor : Get.theme.disabledColor,
                foregroundColor: Get.theme.textTheme.button!.color,
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
                  style: Theme.of(context).textTheme.headline4
                )
              ),
            ),
          ],),
          ]
        ))
      )
    );
  }
}