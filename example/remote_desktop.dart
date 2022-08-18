import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void main(List<String> args) async {
  var client = XdgDesktopPortalClient();
  final deviceTypes = await client.remoteDesktop.createSession();
  print(deviceTypes);
  await client.close();
}
