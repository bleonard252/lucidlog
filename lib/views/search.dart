import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal/db/dream.dart';
import 'package:date_time_format/date_time_format.dart';
import 'package:journal/views/optional_features.dart';
import 'package:journal/widgets/empty_state.dart';
import 'package:journal/main.dart';
import 'package:journal/widgets/gradienticon.dart';
import 'package:mdi/mdi.dart';
import 'package:objectdb/objectdb.dart';
import 'package:path_provider/path_provider.dart';
import 'package:string_similarity/string_similarity.dart';

import 'list.dart' show DreamEntry;
//late List<DreamRecord> dreamList;

enum SearchListMode {
  /// A text-based search in the title or body.
  search,
  /// A filter or list with a displayed title.
  /// Shows a list of recorded **dreams**.
  listOrFilter
}
/// A filter, as used by the search screen
/// to filter elements.
class SearchFilter {
  /// The localized name displayed as the title.
  final String name;
  /// A predicate, as used in [List.where].
  final bool Function(DreamRecord) predicate;
  /// Set to false to force-hide night headers,
  /// and true to allow their display.
  /// Mutually exclusive with the [sorter].
  final bool respectNightly;
  /// Used to sort the entries depending on what's most important.
  /// If this is null, the list is not sorted.
  /// Mutually exclusive with [respectNightly].
  final int Function(DreamRecord a, DreamRecord b)? sorter;
  final List<Widget>? actions;

  SearchFilter({
    required this.name,
    required this.predicate,
    this.respectNightly = false,
    this.sorter,
    this.actions
  }) : assert(respectNightly || sorter == null, "respectNightly and sorter are mutually exclusive.");
}

class SearchScreen extends StatefulWidget {
  final SearchListMode mode;
  final SearchFilter? filter;

  SearchScreen({this.mode = SearchListMode.search, this.filter})
  : assert(mode == SearchListMode.search 
  || (mode == SearchListMode.listOrFilter && filter != null));

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<DreamRecord> list = [];
  late TextEditingController controller;

  Future<void> reloadDreamList() async {
    if (widget.mode == SearchListMode.search) {
      final _list = dreamList.where((document) => 
        document.title.toLowerCase().contains(controller.value.text.toLowerCase())
        || document.body.toLowerCase().contains(controller.value.text.toLowerCase())
      ).toList();
      //list.sort((a, b) => (StringSimilarity.compareTwoStrings(a.title + a.body, b.title + b.body)*3).floor()-2);
      _list.sort((a, b) => (StringSimilarity.compareTwoStrings(controller.value.text.toLowerCase(), (a.title + a.body).toLowerCase())
        .compareTo(StringSimilarity.compareTwoStrings(controller.value.text.toLowerCase(), (b.title + b.body).toLowerCase()))));
      //StringSimilarity.findBestMatch(controller.value.text, _list.map((e) => e.title+"\n"+e.body).toList()).ratings.map((e) => e.target);
      list = _list;
    } else if (widget.mode == SearchListMode.listOrFilter) {
      assert(widget.filter != null, "listOrFilter requires a filter to be set");
      list = dreamList.where(widget.filter!.predicate).toList();
      if (widget.filter?.sorter != null) list.sort(widget.filter!.sorter);
    }
    if (widget.mode == SearchListMode.search && controller.value.text == "") list = [];
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    reloadDreamList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.mode == SearchListMode.listOrFilter ? Text(widget.filter!.name)
        : TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Search",
            border: InputBorder.none
          ),
          onChanged: (v) => reloadDreamList(),
        ),
        actions: controller.value.text == "" && widget.mode == SearchListMode.search
        ? [
          if (OptionalFeatures.counters) IconButton(
            onPressed: () => Get.toNamed("/stats"),
            icon: Icon(Mdi.chartBar)
          )
        ] : widget.filter?.actions,
      ),
      body: list.length > 0 ? ListView.builder(
        itemBuilder: (_, i) => i == 0 && widget.mode == SearchListMode.search ? Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Found ${list.length} results", style: Get.textTheme.button?.copyWith(color: Get.theme.primaryColor)),
          ) : DreamEntry(
          dream: list[widget.mode == SearchListMode.search ? i-1 : i],
          list: (widget.filter?.respectNightly ?? false) && OptionalFeatures.nightly ? list : null
        ),
        itemCount: widget.mode == SearchListMode.search ? list.length+1 : list.length,
      ) : controller.value.text == "" ? widget.mode == SearchListMode.search ? ListView(children: [
        // Padding(
        //   padding: const EdgeInsets.all(8.0),
        //   child: Text("Warning: some of these buttons don't work yet! The below serves as a preview for features I expect to add in the future.\n"
        //   + "However, regular search works exactly how you expect it to."),
        // ),
        ListTile(
          leading: GradientIcon(Icons.cloud, 24.0, purpleGradient),
          title: Text("Filter to Lucid Only"),
          subtitle: Text("Filter to show lucid dreams only"),
          onTap: () => Get.to(() => SearchScreen(
            mode: SearchListMode.listOrFilter,
            filter: SearchFilter(
              name: "Lucid Dreams Only",
              predicate: (dream) => dream.lucid,
              respectNightly: true
            ),
          )),
        ),
        ListTile(
          title: Text("Filter to Non-Lucid Only"),
          onTap: () => Get.to(() => SearchScreen(
            mode: SearchListMode.listOrFilter,
            filter: SearchFilter(
              name: "Non-lucid Dreams Only",
              predicate: (dream) => !dream.lucid,
              respectNightly: true
            ),
          )),
        ).subtile(),
        Divider(height: 0.0),
        if (OptionalFeatures.wildDistinction) ...[ListTile(
          leading: GradientIcon(Mdi.weatherLightning, 24.0, goldGradient),
          title: Text("Filter to WILD Only"),
          subtitle: Text("Filter to show wake-initiated lucid dreams only"),
          onTap: () => Get.to(() => SearchScreen(
            mode: SearchListMode.listOrFilter,
            filter: SearchFilter(
              name: "WILD Only",
              predicate: (dream) => dream.wild,
              respectNightly: true
            ),
          )),
        ),
        ListTile(
          title: Text("Filter to DILD Only"),
          subtitle: Text("Filter to show dream-initiated lucid dreams only"),
          onTap: () => Get.to(() => SearchScreen(
            mode: SearchListMode.listOrFilter,
            filter: SearchFilter(
              name: "DILD Only",
              predicate: (dream) => !dream.wild,
              respectNightly: true
            ),
          )),
        ).subtile(), Divider(height: 0.0)],
        ListTile(
          leading: Icon(Icons.dark_mode),
          title: Text("By Night"),
          subtitle: Text("Search by date"),
          onTap: () async {
            final fromDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: dreamList.last.night,
              lastDate: (DateTime.now().isBefore(dreamList.first.night) ? dreamList.first.night : DateTime.now()).add(Duration(hours: 12))
            );
            if (fromDate == null) return;
            var _nightFormat = sharedPreferences.containsKey("night-format")
            ? sharedPreferences.getString("night-format") ?? "M j" : "M j";
            Get.to(() => SearchScreen(
              mode: SearchListMode.listOrFilter,
              filter: SearchFilter(
                name: "Night of ${fromDate.format(_nightFormat)} to ${fromDate.add(Duration(days: 1)).format(_nightFormat)}",
                predicate: (dream) => dream.night == fromDate,
                respectNightly: false //because they're all on the same night anyway
              ),
            ));
          },
        ),
        Divider(height: 0.0),
        ListTile(
          leading: Icon(Icons.cloud_off),
          title: Text("List Insufficient Recall"),
          subtitle: Text("Find dreams with low recall, and try to finish them."),
          onTap: () => Get.to(() => SearchScreen(
            mode: SearchListMode.listOrFilter,
            filter: SearchFilter(
              name: "Insufficient Recall Only",
              predicate: (dream) => dream.forgotten,
              respectNightly: true
            ),
          )),
        ),
        ListTile(
          title: Text("List Sufficient Recall"),
          onTap: () => Get.to(() => SearchScreen(
            mode: SearchListMode.listOrFilter,
            filter: SearchFilter(
              name: "Sufficient Recall Only",
              predicate: (dream) => !dream.forgotten,
              respectNightly: true
            ),
          )),
        ).subtile(),
        Divider(height: 0.0),
        ListTile(
          leading: Icon(Icons.public),
          title: Text("List Persistent Realms"),
          subtitle: Text("A tool for the talented."),
          enabled: false,
        ),
      ]) : Center(child: EmptyState(
        icon: Icon(Icons.search_off),
        text: Text("No items matched the filter."),
      )) : Center(child: EmptyState(
        icon: Icon(Icons.search_off),
        text: Text("The search uncovered no results. Try revising your search."),
      ))
    );
  }
}

class _Gold extends MaterialStateColor {
  static Color _defaultColor = Colors.amber;
  static Color _pressedColor = Colors.amber.shade700;
  static Color _hoverColor = Colors.amber.withAlpha(48);

  const _Gold() : super(0xffab47bc);

  @override
  Color resolve(Set<MaterialState> states) {
    if (states.contains(MaterialState.pressed)) {
      return _pressedColor;
    }
    return _defaultColor;
  }
}

extension ListSubtile on ListTile {
  @override
  Widget subtile() {
    return ListTile(
      leading: Container(width: 24, height: 0),
      title: title != null ? DefaultTextStyle(
        style: Get.textTheme.button!,
        child: title!
      ) : null,
      dense: true,

      subtitle: subtitle,
      autofocus: autofocus,
      contentPadding: contentPadding,
      enableFeedback: enableFeedback,
      enabled: enabled,
      focusColor: focusColor,
      focusNode: focusNode,
      horizontalTitleGap: horizontalTitleGap,
      hoverColor: hoverColor,
      isThreeLine: isThreeLine,
      key: key,
      minLeadingWidth: minLeadingWidth,
      minVerticalPadding: minVerticalPadding,
      mouseCursor: mouseCursor,
      onLongPress: onLongPress,
      onTap: onTap,
      selected: selected,
      selectedTileColor: selectedTileColor,
      shape: shape,
      tileColor: tileColor,
      trailing: trailing,
      visualDensity: visualDensity,
    );
  }
}