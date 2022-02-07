import 'dart:io';

import 'package:uni_links/uni_links.dart';

File? importedFile;

Future<File?> handleIncomingFile() async {
  final _importedLink = await getInitialLink();
  if (_importedLink != null) importedFile = File(_importedLink);
  else return null;
  //TODO: use the lldj file share check thingy
}