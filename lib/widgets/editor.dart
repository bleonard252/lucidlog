import "package:flutter/material.dart";

class BaseEditor extends StatefulWidget {
  final List<Widget> leftSide;
  final Widget Function(BuildContext context, String pageName) rightSide;
  BaseEditor({ Key? key, required this.leftSide, required this.rightSide }) : super(key: key);

  @override
  _BaseEditorState createState() => _BaseEditorState();

  _EditorController? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_EditorController>();
}

class _BaseEditorState extends State<BaseEditor> {
  @override
  Widget build(BuildContext context) {
    return Container(
      
    );
  }
}

class _EditorController extends InheritedWidget {
  final _BaseEditorState editorState;
  final String? activePage;
  final Map<String, dynamic> values;

  _EditorController({
    this.activePage,
    this.values = const {},
    required this.editorState,
    Key? key,
    required Widget child
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return this != oldWidget;
  }

}