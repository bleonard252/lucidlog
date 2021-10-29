import "package:flutter/material.dart";

class PreflightScreen extends StatelessWidget {
  /// This is displayed on the preflight screen.
  final Widget child;
  //final FutureOr<void> Function(BuildContext) action;

  const PreflightScreen({
    Key? key,
    required this.child,
    //required this.action
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.purple[600],
      theme: ThemeData.dark(),
      title: "LUCIDLOG PREFLIGHT",
      home: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: Colors.black
            ),
          ),
          Positioned.fill(
            child: Center(
              child: child
            ),
          ),
        ],
      ),
    );
  }
}