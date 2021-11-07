import 'dart:async';

import "package:flutter/material.dart";
import 'package:get/get.dart';
import 'package:journal/widgets/empty_state.dart';
import 'package:mdi/mdi.dart';

class BaseEditor extends StatefulWidget {
  final List<Widget> Function(BuildContext context) leftSide;
  final Widget leftSideTitle;
  final Widget? Function(BuildContext context, String pageName) rightSide;
  final Widget? Function(String pageName) rightSideTitle;
  final Widget? emptyRightSide;
  final FutureOr<bool> Function(Map<String, dynamic> values)? onSave;
  final Map<String, dynamic> Function()? initValues;
  final String? defaultPage;
  BaseEditor({
    Key? key,
    required this.leftSide,
    required this.leftSideTitle,
    required this.rightSide,
    required this.rightSideTitle,
    this.emptyRightSide,
    this.onSave,
    this.initValues,
    this.defaultPage
  }) : super(key: key);

  @override
  _BaseEditorState createState() => _BaseEditorState();

  static _EditorController? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_EditorController>();

  static const _breakpoint = 480;
}

class _BaseEditorState extends State<BaseEditor> {

  @override
  void initState() {
    //Future.value(widget.initValues?.call()).then((result) => values = result);
    values = widget.initValues?.call() ?? values;
    activePage = widget.defaultPage ?? activePage;
    super.initState();
  }

  void setActivePage(String? activePage, [bool skipState = false]) {
    if (!skipState) setState(() {
      this.activePage = activePage;
    });
    else this.activePage = activePage;
  }
  void setValue(String key, dynamic value, [bool skipState = false]) {
    if (!skipState) setState(() => values[key] = value);
    else values[key] = value;
  }

  String? activePage;
  Map<String, dynamic> values = {};

  void save() async {
    var success = await widget.onSave?.call(values);
    if (success ?? false) Get.back(closeOverlays: true);
  }

  @override
  Widget build(BuildContext context) {
    return _EditorController(
      editorState: this,
      activePage: activePage,
      values: values,
      child: Builder(
        builder: (context) {
          return Scaffold(
            // The app bar has three states: Desktop, Left, and Right.
            appBar: MediaQuery.of(context).size.width > BaseEditor._breakpoint*2 ? AppBar(
              leading: Tooltip(
                message: "Cancel",
                child: IconButton(
                  onPressed: () => Get.back(closeOverlays: true),
                  icon: Icon(Icons.close)
                )
              ),
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  widget.leftSideTitle,
                  Expanded(child: Container()),
                  if (activePage != null) widget.rightSideTitle(activePage!) ?? Text("")
                ],
              ),
              actions: [
                Tooltip(
                  message: "Save",
                  child: IconButton(
                    onPressed: () => save(),
                    icon: Icon(Icons.save)
                  )
                ),
              ],
            ) : activePage == null ? AppBar(
              leading: Tooltip(
                message: "Cancel",
                child: IconButton(
                  onPressed: () => Get.back(closeOverlays: true),
                  icon: Icon(Icons.close)
                )
              ),
              title: widget.leftSideTitle,
              actions: [
                Tooltip(
                  message: "Save",
                  child: IconButton(
                    onPressed: () => save(),
                    icon: Icon(Icons.save)
                  )
                ),
              ],
            ) : AppBar(
              leading: Tooltip(
                message: "Editor main menu",
                child: IconButton(
                  onPressed: () => BaseEditor.of(context)?.setActivePage(null),
                  icon: Icon(Mdi.menu)
                )
              ),
              title: widget.rightSideTitle(activePage!) ?? widget.leftSideTitle,
              
            ),
            body: Get.mediaQuery.size.width > BaseEditor._breakpoint*2
            ? Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: BaseEditor._breakpoint.toDouble(),
                  child: ListView.separated(
                    itemBuilder: (c, i) => widget.leftSide(context)[i],
                    itemCount: widget.leftSide(context).length,
                    separatorBuilder: (c, i) => Divider(thickness: 4, height: 4),
                  ),
                ),
                Expanded(
                  child: activePage != null ? Builder(
                    builder: (context) => widget.rightSide(context, activePage!) 
                    ?? _buildEmptyRightPage()
                  ) : _buildEmptyRightPage()
                )
              ],
            ) : Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(child: Material(
                  color: Get.theme.canvasColor,
                  child: ListView.separated(
                    itemBuilder: (c, i) => widget.leftSide(context)[i],
                    itemCount: widget.leftSide(context).length,
                    separatorBuilder: (c, i) => Divider(thickness: 4, height: 4),
                  ),
                )),
                if (activePage != null && activePage!.isNotEmpty) Positioned.fill(
                  child: Material(
                    color: Get.theme.canvasColor,
                    child: widget.rightSide(context, activePage!)
                    ?? _buildEmptyRightPageMobile(),
                  )
                )
              ],
            )
          );
        }
      )
    );
  }

  Widget _buildEmptyRightPage() {
    return Center(
      child: EmptyState(
        preflight: false,
        icon: Icon(Mdi.arrowLeftBoldHexagonOutline),
        text: Text("Go over there to edit."),
      )
    );
  }
  Widget _buildEmptyRightPageMobile() {
    return Center(
      child: EmptyState(
        preflight: false,
        icon: Icon(Mdi.arrowLeftBoldHexagonOutline),
        text: Text("Press Back to edit."),
      )
    );
  }
}

class _EditorController extends InheritedWidget {
  final _BaseEditorState _editorState;
  final String? activePage;
  final Map<String, dynamic> values;

  get isDesktopMode => Get.mediaQuery.size.width > BaseEditor._breakpoint*2;

  _EditorController({
    this.activePage,
    this.values = const {},
    required _BaseEditorState editorState,
    Key? key,
    required Widget child
  }) : _editorState = editorState, super(key: key, child: child);

  get setActivePage => _editorState.setActivePage;
  get setValue => _editorState.setValue;
  get forceSave => _editorState.save;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return this != oldWidget;
  }

}

class EditorRightPaneButton extends StatelessWidget {
  final ListTile listTile;
  final String targetPageName;
  /// Open a page in the right pane.
  EditorRightPaneButton(this.listTile, this.targetPageName) : super(key: listTile.key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: null,
      autofocus: listTile.autofocus,
      contentPadding: listTile.contentPadding,
      dense: listTile.dense,
      enableFeedback: listTile.enableFeedback,
      enabled: listTile.enabled,
      focusColor: listTile.focusColor,
      focusNode: listTile.focusNode,
      horizontalTitleGap: listTile.horizontalTitleGap,
      hoverColor: listTile.hoverColor,
      isThreeLine: listTile.isThreeLine,
      leading: listTile.leading,
      minLeadingWidth: listTile.minLeadingWidth,
      minVerticalPadding: listTile.minVerticalPadding,
      mouseCursor: listTile.mouseCursor,
      onLongPress: null,
      onTap: () {
        BaseEditor.of(context)?.setValue("_hasCompletedInitialFlow", true, true);
        BaseEditor.of(context)?.setActivePage(targetPageName);
      },
      selected: BaseEditor.of(context)?.activePage == targetPageName,
      selectedTileColor: listTile.selectedTileColor,
      shape: listTile.shape,
      subtitle: listTile.subtitle,
      tileColor: listTile.tileColor,
      title: listTile.title,
      trailing: Icon(Mdi.arrowRight),
      visualDensity: listTile.visualDensity,
    );
  }
}

class EditorToggleButton extends StatelessWidget {
  final String valueKey;
  final Widget? title;
  final Widget? subtitle;
  final Widget? leading;
  final bool enabled;
  
  const EditorToggleButton({
    Key? key,
    required this.valueKey,
    this.title,
    this.subtitle,
    this.leading,
    this.enabled = true
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: enabled ? Switch(
        value: BaseEditor.of(context)?.values[valueKey] ?? false,
        onChanged: (newValue) => BaseEditor.of(context)?.setValue(valueKey, newValue),
      ) : Switch(
        value: false,
        onChanged: (newValue) => false,
      ),
      enabled: enabled,
      onTap: () => BaseEditor.of(context)?.setValue(valueKey, !(BaseEditor.of(context)?.values[valueKey] ?? false)),
    );
  }
}