import "package:flutter/material.dart";
import 'package:journal/main.dart';
import 'package:journal/views/details.dart';
import 'package:journal/widgets/gradienticon.dart';

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
            leading: GradientIcon(Icons.cloud, 24.0, purpleGradient),
            title: Text("Lucid Dreams: ${dreamList.lucids.length}"),
            subtitle: Text("Non-Lucid Dreams: ${dreamList.where((e) => !e.lucid).length}\n"
            "Total dreams journaled: ${dreamList.length}"),
          ),
          ListTile(
            leading: GradientIcon(Icons.cloud, 24.0, purpleGradient),
            title: Text("Lucid Dreams: ${dreamList.lucids.length}"),
            subtitle: Text("Non-Lucid Dreams: ${dreamList.where((e) => !e.lucid).length}\n"
            "Total dreams journaled: ${dreamList.length}"),
          ),
        ],
      ),
    );
  }
}