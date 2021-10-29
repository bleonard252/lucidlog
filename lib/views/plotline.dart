import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:journal/db/dream.dart';
import 'package:journal/db/plotline.dart';
import 'package:journal/views/optional_features.dart';

class PlotlineWidget extends StatefulWidget {
  final DreamRecord dream;
  const PlotlineWidget({ Key? key, required this.dream }) : super(key: key);

  @override
  _PlotlineWidgetState createState() => _PlotlineWidgetState();
}

class _PlotlineWidgetState extends State<PlotlineWidget> {
  late List<PlotPointRecord> list;
  late Future gotFile;
  double currentPoint = OptionalFeatures.plotlines == PlotlineTypes.EXPANDABLE ? -1 : 0;

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
                  headerBuilder: (_, __) => Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      point.subtitle ?? "Scene "+(list.indexOf(point)+1).toString(),
                      style: Get.textTheme.headline6
                    ),
                  ), 
                  body: Align(
                    alignment: Alignment.topLeft,
                    child: MarkdownBody(
                      data: point.body,
                      selectable: true,
                      softLineBreak: true,
                    ),
                  ),
                  canTapOnHeader: true,
                  isExpanded: currentPoint == list.indexOf(point)
                )
              ],
              expansionCallback: (index, activated) => setState(() => currentPoint = activated ? -1 : index.toDouble()),
            );
          case PlotlineTypes.SLIDER:
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Slider(
                value: currentPoint,
                onChanged: (newPoint) => setState(() => currentPoint = newPoint),
                label: list[currentPoint.floor()].subtitle ?? "Scene "+(currentPoint+1).floor().toString(),
                divisions: list.length - 1,
                min: 0,
                max: list.length - 1,
              ),
              Text(list[currentPoint.floor()].subtitle ?? "Scene "+(currentPoint+1).floor().toString(), 
                style: Get.textTheme.subtitle1?.copyWith(fontWeight: FontWeight.w700)),
              MarkdownBody(
                data: list[currentPoint.floor()].body,
                selectable: true,
                softLineBreak: true,
              )
            ], mainAxisSize: MainAxisSize.min);
          default:
            return Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.lightbulb, color: Get.theme.colorScheme.secondary),
                ),
                Flexible(
                  flex: 0,
                  fit: FlexFit.loose,
                  child: Text("This entry has information for the Plotlines feature.\nEnable it to read more.",
                    style: TextStyle(color: Get.theme.colorScheme.secondary)
                  ),
                )
              ],
            );
        }
      }
    );
  }
}