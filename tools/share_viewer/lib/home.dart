import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import "package:flutter/material.dart";
import 'package:journal/views/details.dart';
import 'package:journal/views/list.dart';
import 'package:journal/views/realms/details.dart';
import 'package:lldj_share_viewer/check.dart';
import 'package:lldj_share_viewer/main.dart';
import 'package:tar/tar.dart';

class ShareViewerHomeScreen extends StatefulWidget {
  const ShareViewerHomeScreen({ Key? key }) : super(key: key);

  @override
  _ShareViewerHomeScreenState createState() => _ShareViewerHomeScreenState();
}

class _ShareViewerHomeScreenState extends State<ShareViewerHomeScreen> {
  final TextEditingController urlController = TextEditingController();
  String? _errorMessage;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => setState(() {
        _isDragging = true;
      }),
      onDragExited: (_) => setState(() {
        _isDragging = false;
      }),
      onDragDone: (details) async {
        setState(() {
          _isDragging = false;
        });
        if (details.files.length == 0) return;
        else if (details.files.length > 1) {
          setState(() {
            _errorMessage = "Please drop one file at a time.";
          });
          return;
        }
        try {
          final reader = TarReader(details.files.single.openRead().map((event) => event.toList()).transform(gzip.decoder));
          final _page = await checkUploadedFile(reader);
          if (_page?.dream != null) {
            Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (context) => DreamDetails(
                _page!.dream!,
                isLimited: true,
              )
            ));
          } else if (_page?.realm != null) {
            Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (context) => RealmDetails(
                _page!.realm!,
                isLimited: true,
              )
            ));
          } else {
            setState(() {
              _errorMessage = "The file you dropped is not a Lucidlog shared file.";
            });
          }
        } catch(e) {
          setState(() {
            _errorMessage = "The file you dropped is not a Lucidlog file.";
          });
        }
      },
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              //Image.asset("assets/Notification.png"),
              if (_errorMessage?.isNotEmpty == true) Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red)
              ),
              // TextField(
              //   controller: urlController,
              //   decoration: InputDecoration(
              //     hintText: "File URL"
              //   ),
              // ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  child: Text("Upload file"),
                  onPressed: () {
                    FilePicker.platform.pickFiles(
                      allowedExtensions: ["*.lldj"],
                      dialogTitle: "Select the .lldj share file to use",
                      allowMultiple: false,
                      withData: true,
                    ).then((value) async {
                      if (value == null) return;
                      try {
                        final reader = TarReader(Stream.value(value.files[0].bytes!.toList()).transform(gzip.decoder));
                        final _page = await checkUploadedFile(reader);
                        if (_page?.dream != null) {
                          Navigator.pushReplacement(context, MaterialPageRoute(
                            builder: (context) => DreamDetails(
                              _page!.dream!,
                              isLimited: true,
                            )
                          ));
                        } else if (_page?.realm != null) {
                          Navigator.pushReplacement(context, MaterialPageRoute(
                            builder: (context) => RealmDetails(
                              _page!.realm!,
                              isLimited: true,
                            )
                          ));
                        } else {
                          setState(() {
                            _errorMessage = "The file you selected is not a Lucidlog shared file.";
                          });
                        }
                      } catch(e) {
                        setState(() {
                          _errorMessage = "The file you selected is not a Lucidlog file.";
                        });
                      }
                    });
                  }
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}