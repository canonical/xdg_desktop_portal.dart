import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void main(List<String> args) async {
  var client = XdgDesktopPortalClient();
  final reason = 'Allow your application to run in the background.';
  final autostart = false;
  var result = await client.background.requestBackground(
    reason: reason,
    autostart: autostart,
    commandLine: ['gedit'],
  ).first;
  print('$result');
  await client.close();
}
