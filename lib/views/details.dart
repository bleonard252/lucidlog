import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:journal/db/comment.dart';
import 'package:journal/db/dream.dart';
import 'package:journal/db/plotline.dart';
import 'package:journal/main.dart';
import 'package:journal/views/comments.dart';
import 'package:journal/views/optional_features.dart';
import 'package:journal/views/plotline.dart';
import 'package:journal/views/search.dart';
import 'package:journal/widgets/gradienticon.dart';
import 'package:mdi/mdi.dart';
import 'package:date_time_format/date_time_format.dart';
import 'package:share_plus/share_plus.dart';

extension DreamList on List<DreamRecord> {
  List<DreamRecord> get lucids => this.where((element) => element.lucid).toList();
  List<DreamRecord> get wilds => this.where((element) => element.wild).toList();
  List<DreamRecord> sameNight({required DreamRecord as}) => this.where((element) => element.night == as.night).toList();
  /// Quickly returns all of the documents in this list in a JSON-compatible format.
  List<Map> toListOfMap() => this.map((e) => e.toJSON()).toList();
}

class DreamDetails extends StatelessWidget {
  final DreamRecord dream;
  final List<DreamRecord>? list = dreamList.reversed.toList();

  DreamDetails(this.dream, {Key? key}) : super(key: key);

  List<String> calculateCounters() {
    assert(list != null && list != [], "Counters must be enabled and list must be given");
    List<String> output = [];
    output.add("Dream "+(list!.lastIndexOf(dream)+1).toString());
    if (dream.lucid) output.add("LD "+(list!.lucids.lastIndexOf(dream)+1).toString());
    if (OptionalFeatures.wildDistinction && dream.wild)
      output.add("WILD "+(list!.wilds.indexOf(dream)+1).toString());
    if (list!.sameNight(as: dream).length > 1) 
      output.add("Dream ${list!.sameNight(as: dream).indexOf(dream)+1} of ${list!.sameNight(as: dream).length} of the night");
    // TODO: streaks!
    return output;
  }
  
  @override
  Widget build(BuildContext context) {
    var _dateFormat = sharedPreferences.containsKey("datetime-format")
      ? sharedPreferences.getString("datetime-format") : DateTimeFormats.commonLogFormat;
    var _nightFormat = sharedPreferences.containsKey("night-format")
      ? sharedPreferences.getString("night-format") ?? "M j" : "M j";
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
                  icon: Icon(Icons.share),
                  onPressed: () => Share.share("**${dream.title}** *from ${dream.timestamp.format(_dateFormat ?? DateTimeFormats.commonLogFormat)}*\n"
                  "${dream.body}", subject: dream.title)
                ),
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
                    gradient: dream.forgotten ? redGradient : dream.type.gradient, //dream.lucid ? dream.wild ? goldGradient : purpleGradient : dream.forgotten ? redGradient : null,
                    color: Colors.grey
                  ),
                  //backgroundColor: dream.lucid ? Get.theme.primaryColor : Get.theme.disabledColor,
                  //foregroundColor: Get.textTheme.button!.color,
                  child: Icon(dream.type.icon)
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          dream.title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                          style: Get.textTheme.headline4
                        ),
                      ],
                    ),
                  )
                ),
              ),
            ],),
            if (dream.body.isNotEmpty) Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              width: double.infinity,
              child: Material(
                elevation: 2,
                type: MaterialType.card,
                color: Get.theme.cardColor,
                borderRadius: BorderRadius.all(Radius.circular(0)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children:[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("Summary", 
                      style: Get.textTheme.subtitle1?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: MarkdownBody(
                      data: dream.body,
                      selectable: true,
                      softLineBreak: true,
                    )
                  ),
                  FutureBuilder(
                    future: dream.plotFile.exists(),
                    builder: (ctx, snap) => snap.hasData && snap.data == true ? Flexible(
                      fit: FlexFit.loose,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: PlotlineWidget(dream: dream)
                      ),
                    ) : Container()
                  )
                ])
              )
            ),
            if (dream.tags.isNotEmpty) Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              width: double.infinity,
              child: Material(
                elevation: 2,
                type: MaterialType.card,
                color: Get.theme.cardColor,
                borderRadius: BorderRadius.all(Radius.circular(0)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("Tags", 
                      style: Get.textTheme.subtitle1?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      direction: Axis.horizontal,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      children: [
                      for (var tag in dream.tags) Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Chip(
                          label: Text(tag)
                        )
                      ),
                    ])
                  )
                ])
              )
            ),
            if (dream.methods.isNotEmpty) Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              width: double.infinity,
              child: Material(
                elevation: 2,
                type: MaterialType.card,
                color: Get.theme.cardColor,
                borderRadius: BorderRadius.all(Radius.circular(0)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("Techniques used",
                      style: Get.textTheme.subtitle1?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      direction: Axis.horizontal,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      children: [
                        if (dream.methods.contains("WILD") && OptionalFeatures.wildDistinction) Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Chip(
                            backgroundColor: Colors.amber,
                            labelStyle: TextStyle(color: Colors.black),
                            label: Text("WILD")
                          )
                        ),
                        if (dream.methods.contains("SSILD") && OptionalFeatures.wildDistinction) Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Chip(
                            backgroundColor: Colors.amber,
                            labelStyle: TextStyle(color: Colors.black),
                            label: Text("SSILD")
                          )
                        ),
                        if (dream.methods.contains("DEILD") && OptionalFeatures.wildDistinction) Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Chip(
                            backgroundColor: Colors.amber,
                            labelStyle: TextStyle(color: Colors.black),
                            label: Text("DEILD")
                          )
                        ),
                        for (var tag in dream.methods) if (!((tag == "WILD" || tag == "SSILD" || tag == "DEILD") && OptionalFeatures.wildDistinction)) Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Chip(
                            backgroundColor: sharedPreferences.getStringList("ld-methods")?.contains(tag)??false ? Colors.grey.shade600 : Colors.redAccent.shade700,
                            label: Text(tag)
                          )
                        ),
                      ]
                    )
                  )
                ])
              )
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Material(
                elevation: 2,
                type: MaterialType.card,
                color: Get.theme.cardColor,
                borderRadius: BorderRadius.all(Radius.circular(0)),
                child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Padding(
                  //   padding: const EdgeInsets.all(8.0),
                  //   child: Text("User Information", style: Get.textTheme.subtitle1?.copyWith(fontWeight: FontWeight.w700)),
                  // ),
                  ListTile(
                    // leading: dream.lucid ? dream.wild ? GradientIcon(Mdi.weatherLightning, 24, goldGradient)
                    // : GradientIcon(Icons.cloud, 24, purpleGradient) 
                    // : Icon(Icons.cloud_outlined),
                    leading: Icon(dream.type.icon),
                    title: Text("Type"),
                    subtitle: Text(dream.type.name) //Text(dream.lucid ? dream.wild ? "WILD Lucid Dream" : "DILD Lucid Dream" : "Non-Lucid Dream", maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false),
                  ),
                  ListTile(
                    leading: Icon(dream.forgotten ? Icons.cloud_off : Icons.cloud_done_outlined),
                    title: Text("Recall"),
                    subtitle: Text(dream.forgotten ? "Insufficient" : "Sufficient", maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false),
                  ),
                  if (dream.timestamp != DreamRecord.dtzero) ListTile(
                    leading: Icon(Icons.calendar_today),
                    title: Text("Date and Time"),
                    subtitle: Text(dream.timestamp.format(_dateFormat ?? DateTimeFormats.commonLogFormat), 
                      maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false),
                    onTap: () => Get.to(() => SearchScreen(
                      mode: SearchListMode.listOrFilter,
                      filter: SearchFilter(
                        name: "Night of ${dream.night.format(_nightFormat)} to ${dream.night.add(Duration(days: 1)).format(_nightFormat)}",
                        predicate: (otherdream) => otherdream.night == dream.night,
                        respectNightly: true
                      ),
                    )),
                  ),
                  if (OptionalFeatures.counters) ListTile(
                    leading: Icon(Mdi.clockOutline),
                    title: Text("Counters"),
                    subtitle: Text(calculateCounters().join(", ")),
                  )
                ]))
              ),
            ),
            if (OptionalFeatures.comments) DetailsCommentsSection(dream: dream)
          ]
        ))
      )
    );
  }
}
