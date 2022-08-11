import 'dart:io';

import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void main(List<String> args) async {
  var client = XdgDesktopPortalClient();
  await File('FD_TEST').writeAsString('Hello World!', flush: true);
  var file = await File('FD_TEST').open();
  await client.secret.retrieveSecret(file, token: '123');
  await client.close();
}
