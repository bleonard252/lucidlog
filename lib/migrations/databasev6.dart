import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:journal/main.dart';
import 'package:journal/widgets/empty_state.dart';
import 'package:journal/widgets/preflight.dart';
import 'package:objectdb/objectdb.dart';
import 'package:objectdb/src/objectdb_storage_filesystem.dart';
import 'package:path_provider/path_provider.dart';

Future<void> databaseMigrationVersion6() async {
  final databaseDirectory = Platform.isIOS ? (await getApplicationDocumentsDirectory()).absolute.path
    : platformStorageDir.absolute.path;
  final v5Database = ObjectDB(FileSystemStorage(databaseDirectory + "/dreamjournal.db"));
  final v5DatabaseFile = File(databaseDirectory + "/dreamjournal.db");
  final v6DatabaseFile = File(databaseDirectory + "/dreamjournal.json");
  final _v6DbFileExists = await v6DatabaseFile.exists();
  if (_v6DbFileExists) {
    return runApp(PreflightScreen(child: EmptyState(
      preflight: true,
      icon: Icon(Icons.warning, color: Colors.red),
      text: Text("Error: file exists! Could not migrate database\n"
      + databaseDirectory + "/dreamjournal.json", style: TextStyle(color: Colors.red))
    )));
  }
  final _v5DatabaseList = await v5Database.find({});
  await v6DatabaseFile.writeAsString(jsonEncode(_v5DatabaseList));
  v5Database.close();
  //await v5DatabaseFile.delete();
  return;
}