import 'dart:convert';

import 'package:date_time_format/date_time_format.dart';
import 'package:journal/db/dream.dart';
import 'package:journal/db/plotline.dart';
import 'package:journal/main.dart';

/// Creates a standard Markdown file from this journal entry,
/// which can be added to a Jekyll or other markdown-based
/// website easily.
Future<String> toMarkdownDocument(DreamRecord dream) async {
  var out = <String>[];
  out.add("---\n"
  "title: ${dream.title}\n"
  "date: ${dream.timestamp.toIso8601String()}\n"
  "lucid: ${dream.lucid ? "yes" : "no"}\n"
  "---");
  out.add("# "+dream.title);
  out.add(dream.body);
  late final List<PlotPointRecord> plotList;
  await dream.plotFile.readAsString().then((value) => 
    plotList = (jsonDecode(value) as List).map<PlotPointRecord>((e) => 
      PlotPointRecord(body: e["body"] ?? "No body provided, somehow!", subtitle: e["subtitle"])
    ).toList()
  ).onError((error, stackTrace) => plotList = const <PlotPointRecord>[]);
  for (var plotPoint in plotList) {
    out.add("## "+(plotPoint.subtitle ?? "Scene "+plotList.indexOf(plotPoint).toString()));
    out.add(plotPoint.body);
  }
  return out.join("\n");
}

/// Creates Discord-compatible Markdown.
Future<String> toDiscordMarkdown(DreamRecord dream) async {
  var out = <String>[];
  var _dateFormat = sharedPreferences.containsKey("datetime-format")
  ? sharedPreferences.getString("datetime-format") : DateTimeFormats.commonLogFormat;
  out.add("__**"+dream.title+"** "+dream.timestamp.format(_dateFormat ?? DateTimeFormats.commonLogFormat)+"__");
  out.add("> "+dream.body.replaceAll("\n", "\n> "));
  late final List<PlotPointRecord> plotList;
  await dream.plotFile.readAsString().then((value) => 
    plotList = (jsonDecode(value) as List).map<PlotPointRecord>((e) => 
      PlotPointRecord(body: e["body"] ?? "No body provided, somehow!", subtitle: e["subtitle"])
    ).toList()
  ).onError((error, stackTrace) => plotList = const <PlotPointRecord>[]);
  for (var plotPoint in plotList) {
    out.add("**"+(plotPoint.subtitle ?? "Scene "+plotList.indexOf(plotPoint).toString())+"**");
    out.add("> "+plotPoint.body.replaceAll("\n", "\n> "));
  }
  return out.join("\n");
}