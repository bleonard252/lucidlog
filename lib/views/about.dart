import "package:flutter/material.dart";
import 'package:get/get.dart';
import 'package:journal/main.dart';
import 'package:mdi/mdi.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: must_be_immutable
class AboutScreen extends StatelessWidget {
  AboutScreen({ Key? key }) : super(key: key);

  int _profileNumber = profileNumber;

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
          child: Text("Version "+(appVersion ?? "not found"), style: Get.textTheme.headline6),
        ),
        ListTile(
          title: Text("Licenses"),
          leading: Icon(Mdi.license),
          onTap: () => showLicensePage(context: context, applicationName: "LucidLog Dream Journal"),
        ),
        ListTile(
          title: Text("Privacy"),
          subtitle: Text("No personal information is collected and no data leaves the app without your direct instruction."),
          leading: Icon(Mdi.noteText),
          onTap: () => launch("https://resources.dreamstation.one/appendix/app-policy"),
        ),
        // ListTile(
        //   title: Text("Revert to database from v5"),
        //   leading: Icon(Mdi.numeric5BoxOutline),
        //   onTap: () async {
        //     await sharedPreferences.setString("last-version", "5");
        //     exit(0);
        //   },
        // ),
        ListTile(
          leading: Icon(Mdi.xml),
          title: Text("Source Code"),
          subtitle: Text("https://github.com/bleonard252/lucidlog"),
          onTap: () => launch("https://github.com/bleonard252/lucidlog"),
        ),
        if (profileNumber > 0) ListTile(
          leading: Icon(Mdi.accountMultiple),
          title: Text("Profiles"),
          subtitle: Column(
            children: [
              StatefulBuilder(
                builder: (context, setState) => Slider(
                  value: _profileNumber.toDouble(),
                  divisions: 2,
                  max: 3,
                  min: 1,
                  onChanged: (nv) {
                    setState(() => _profileNumber = nv.floor());
                    sharedPreferences.setInt("profile", _profileNumber);
                  }
                ),
              ),
              Text("Use Profiles for experimentation with the app, or to synchronize with other devices. You must restart the app for this to take effect.")
            ],
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
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