import "package:flutter/material.dart";
import 'package:get/get.dart';
import 'package:mdi/mdi.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
      ),
      body: ListView(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text("LucidLog Dream Journal", style: Get.textTheme.headline4),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text("Version 5", style: Get.textTheme.headline6),
        ),
        ListTile(
          title: Text("Licenses"),
          leading: Icon(Mdi.license),
          onTap: () => showLicensePage(context: context, applicationName: "LucidLog Dream Journal"),
        ),
        ListTile(
          leading: Icon(Mdi.xml),
          title: Text("Source Code"),
          subtitle: Text("https://github.com/bleonard252/lucidlog"),
          onTap: () => launch("https://github.com/bleonard252/lucidlog"),
        ),
        // ListTile(
        //   leading: Icon(SimpleIcons.discord),
        //   title: Text("Support Server"),
        //   subtitle: Text("discord.gg/???"),
        //   onTap: () => launch("https://github.com/bleonard252/lucidlog"),
        // )
      ]),
    );
  }
}