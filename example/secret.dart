import 'dart:io';
import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void main(List<String> args) async {
  var dir = Directory.systemTemp.createTempSync();
  var file = await File('${dir.path}/MASTER_SECRETE').create();
  var accessFile = await file.open(mode: FileMode.write);

  var client = XdgDesktopPortalClient();
  await client.secret.retrieveSecret(accessFile);
  await client.close();

  accessFile.setPositionSync(0);
  final length = accessFile.lengthSync();
  final secret = accessFile.readSync(length);
  await accessFile.close();
  print('Master secret: $secret');
  dir.deleteSync(recursive: true);
}
