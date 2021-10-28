import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:journal/db/dream.dart';
import 'package:journal/db/plotline.dart';
import 'package:journal/views/optional_features.dart';
import 'package:mdi/mdi.dart';

class PlotlineWidget extends StatefulWidget {
  final DreamRecord dream;
  const PlotlineWidget({ Key? key, required this.dream }) : super(key: key);

  @override
  _PlotlineWidgetState createState() => _PlotlineWidgetState();
}

class _PlotlineWidgetState extends State<PlotlineWidget> {
  late List<PlotPointRecord> list;
  late Future gotFile;
  double currentPoint = 0;

  @override
  void initState() {
    super.initState();
    gotFile = widget.dream.plotFile.readAsString().then((value) => 
      list = (jsonDecode(value) as List).map<PlotPointRecord>((e) => 
        PlotPointRecord(body: e["body"] ?? "No body provided, somehow!", subtitle: e["subtitle"])
      ).toList()
    ).onError((error, stackTrace) => list = []);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: gotFile,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [CircularProgressIndicator(value: null)],
        );
        if (list.isEmpty) return Container();
        switch (OptionalFeatures.plotlines) {
          case PlotlineTypes.EXPANDABLE:
            return ExpansionPanelList(
              children: [
                for (final point in list) ExpansionPanel(
                  headerBuilder: (_, __) => Text(point.subtitle ?? "Scene "+(list.indexOf(point)+1).toString()), 
                  body: Text(point.body)
                )
              ],
            );
          case PlotlineTypes.SLIDER:
            return Column(children: [
              Slider(
                value: currentPoint,
                onChanged: (newPoint) => currentPoint = newPoint,
                label: list[currentPoint.floor()].subtitle ?? "Scene "+(currentPoint+1).toString(),
                divisions: list.length,
                min: 0,
                max: list.length - 1,
              ),
              Text(list[currentPoint.floor()].body)
            ]);
          default:
            return Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lightbulb),
                Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Text("This dream has Plotlines information. Enable it to read more."),
                )
              ],
            );
        }
      }
    );
  }
}