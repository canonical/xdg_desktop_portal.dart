import 'dart:io';

import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: trash <path>');
    return;
  }
  var path = args[0];

  var client = XdgDesktopPortalClient();
  await client.trash.trashFile(File(path));
  await client.close();
}
