import "package:flutter/material.dart";
import 'package:journal/main.dart';
import 'package:journal/views/details.dart';
import 'package:journal/views/optional_features.dart';
import 'package:journal/widgets/gradienticon.dart';
import 'package:mdi/mdi.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Statistics"),
        elevation: 0,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.cloud_outlined),
            title: Text("Total dreams journaled: ${dreamList.length}"),
          ),
          ListTile(
            leading: GradientIcon(Icons.cloud, 24.0, purpleGradient),
            title: Text("Lucid Dreams: ${dreamList.lucids.length}"),
            subtitle: Text("Non-Lucid Dreams: ${dreamList.where((e) => !e.lucid).length}"),
            //isThreeLine: true,
          ),
          ListTile(
            leading: GradientIcon(Mdi.weatherLightning, 24.0, goldGradient),
            title: Text("Wake-Induced Lucid Dreams: ${dreamList.wilds.length}"),
            subtitle: Text("Dream-Induced Lucid Dreams: ${dreamList.where((e) => e.lucid && !e.wild).length}"),
            //isThreeLine: true,
          ),
          if (OptionalFeatures.realms) ListTile(
            leading: GradientIcon(Icons.public, 24.0, blueGreenGradient),
            title: Text("Persistent Realms: ${realmList.length}"),
            subtitle: Text("Dreams in PRs: ${dreamList.where((e) => e.realm?.isNotEmpty ?? false).length}"),
            //isThreeLine: true,
          ),
        ],
      ),
    );
  }
}