import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:journal/db/dream.dart';
import 'package:journal/db/realm.dart';
import 'package:journal/main.dart';
import 'package:journal/views/comments.dart';
import 'package:journal/views/list.dart';
import 'package:journal/views/optional_features.dart';
import 'package:journal/widgets/empty_state.dart';
import 'package:mdi/mdi.dart';
import 'package:date_time_format/date_time_format.dart';

extension RealmList on List<RealmRecord> {
  List<Map> toListOfMap() => this.map((e) => e.toJSON()).toList();
}

// ignore: must_be_immutable
class RealmDetails extends StatelessWidget {
  final RealmRecord realm;
  //final List<RealmRecord>? list = realmList.reversed.toList();
  late final List<DreamRecord> dreams;
  bool _isDreamListPopulated = false;

  RealmDetails(this.realm, {Key? key}) : super(key: key);

  // List<String> calculateCounters() {
  //   assert(list != null && list != [], "Counters must be enabled and list must be given");
  //   List<String> output = [];
  //   output.add("Dream "+(list!.lastIndexOf(dream)+1).toString());
  //   if (dream.lucid) output.add("LD "+(list!.lucids.lastIndexOf(dream)+1).toString());
  //   if (OptionalFeatures.wildDistinction && dream.wild)
  //     output.add("WILD "+(list!.wilds.indexOf(dream)+1).toString());
  //   if (list!.sameNight(as: dream).length > 1) 
  //     output.add("Dream ${list!.sameNight(as: dream).indexOf(dream)+1} of ${list!.sameNight(as: dream).length} of the night");
  //   // TODO: streaks!
  //   return output;
  // }
  
  @override
  Widget build(BuildContext context) {
    if (!_isDreamListPopulated) {
      dreams = realm.includedDreams();
      _isDreamListPopulated = true;
    }
    var _dateFormat = sharedPreferences.containsKey("datetime-format")
      ? sharedPreferences.getString("datetime-format") : DateTimeFormats.commonLogFormat;
    // var _nightFormat = sharedPreferences.containsKey("night-format")
    //   ? sharedPreferences.getString("night-format") ?? "M j" : "M j";
    return Scaffold(
      backgroundColor: Get.theme.canvasColor,
      body: Container(
        width: 640,
        alignment: Alignment.topCenter,
        child: Column(
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
                  // IconButton(
                  //   icon: Icon(Icons.share),
                  //   onPressed: () => Share.share("**${realm.title}** *from ${realm.timestamp.format(_dateFormat ?? DateTimeFormats.commonLogFormat)}*\n"
                  //   "${realm.body}", subject: realm.title)
                  // ),
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => Get.offAndToNamed("/realms/edit", arguments: realm)
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
                      gradient: blueGreenGradient,
                      color: Colors.teal
                    ),
                    //backgroundColor: dream.lucid ? Get.theme.primaryColor : Get.theme.disabledColor,
                    //foregroundColor: Get.textTheme.button!.color,
                    child: Icon(Icons.public)
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
                            realm.title,
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
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(mainAxisSize: MainAxisSize.max, children: [
                    TabBar(
                      indicatorPadding: EdgeInsets.all(0.0),
                      indicatorWeight: 4.0,
                      indicator: ShapeDecoration(
                        shape: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.transparent, width: 0, style: BorderStyle.solid)
                        ),
                        gradient: blueGreenGradient.scale(1),
                      ),
                      labelPadding: EdgeInsets.only(left: 0.0, right: 0.0),
                      tabs: [
                        Container(
                          height: 40,
                          alignment: Alignment.center,
                          color: Get.theme.canvasColor,
                          child: Text("Details"),
                        ),
                        Container(
                          height: 40,
                          alignment: Alignment.center,
                          color: Get.theme.canvasColor,
                          child: Text("Dreams"),
                        ),
                      ]
                    ),
                    Expanded(
                      child: TabBarView(children: [
                        ListView(children: [
                          if (realm.body.isNotEmpty) Container(
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
                                    data: realm.body,
                                    selectable: true,
                                    softLineBreak: true,
                                  )
                                ),
                                // FutureBuilder(
                                //   future: realm.plotFile.exists(),
                                //   builder: (ctx, snap) => snap.hasData && snap.data == true ? Flexible(
                                //     fit: FlexFit.loose,
                                //     child: Padding(
                                //       padding: const EdgeInsets.all(8.0),
                                //       child: PlotlineWidget(dream: realm)
                                //     ),
                                //   ) : Container()
                                // )
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
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                // ListTile(
                                //   // leading: dream.lucid ? dream.wild ? GradientIcon(Mdi.weatherLightning, 24, goldGradient)
                                //   // : GradientIcon(Icons.cloud, 24, purpleGradient) 
                                //   // : Icon(Icons.cloud_outlined),
                                //   leading: Icon(realm.type.icon),
                                //   title: Text("Type"),
                                //   subtitle: Text(realm.type.name) //Text(dream.lucid ? dream.wild ? "WILD Lucid Dream" : "DILD Lucid Dream" : "Non-Lucid Dream", maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false),
                                // ),
                                // ListTile(
                                //   leading: Icon(realm.forgotten ? Icons.cloud_off : Icons.cloud_done_outlined),
                                //   title: Text("Recall"),
                                //   subtitle: Text(realm.forgotten ? "Insufficient" : "Sufficient", maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false),
                                // ),
                                if (realm.timestamp != DreamRecord.dtzero && dreams.isNotEmpty
                                && realm.timestamp != dreams.last.timestamp) ListTile(
                                  leading: Icon(Icons.calendar_today),
                                  title: Text("Latest included dream"),
                                  subtitle: Text(realm.timestamp.format(_dateFormat ?? DateTimeFormats.commonLogFormat), 
                                    maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false),
                                  // onTap: () => Get.to(() => SearchScreen(
                                  //   mode: SearchListMode.listOrFilter,
                                  //   filter: SearchFilter(
                                  //     name: "Night of ${realm.night.format(_nightFormat)} to ${realm.night.add(Duration(days: 1)).format(_nightFormat)}",
                                  //     predicate: (otherdream) => otherdream.night == realm.night,
                                  //     respectNightly: true
                                  //   ),
                                  // )),
                                ),
                                if (dreams.isNotEmpty) ListTile(
                                  leading: Icon(Mdi.starFourPoints),
                                  title: Text("Founded"),
                                  subtitle: Text(dreams.last.timestamp.format(_dateFormat ?? DateTimeFormats.commonLogFormat) +"\n"
                                  +dreams.last.title, 
                                    maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false),
                                  onTap: () => Get.toNamed("/dreams/details", arguments: dreams.last)
                                ) else ListTile(
                                  leading: Icon(Mdi.starFourPointsOutline),
                                  title: Text("Not founded yet"),
                                  subtitle: Text("Add a dream to this PR to \"found\" it!", 
                                    maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false)
                                )
                                // if (OptionalFeatures.counters) ListTile(
                                //   leading: Icon(Mdi.clockOutline),
                                //   title: Text("Counters"),
                                //   subtitle: Text(calculateCounters().join(", ")),
                                // )
                              ])
                            ),
                          ),
                          if (OptionalFeatures.comments) DetailsCommentsSection(dream: realm)
                        ]
                      ),
                      dreams.length > 0 ? ListView.builder(
                        itemBuilder: (_, i) => DreamEntry(dream: dreams[i], list: dreams, showCanonStatus: true),
                        itemCount: dreams.length,
                      ) : Center(child: EmptyState(
                        icon: Icon(Mdi.textBoxPlusOutline),
                        text: Text("No dreams are considered part of this PR yet."),
                      ))
                                    ]),
                    )
                ]),
                          ),
              )]
        )
      )
    );
  }
}
