import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void main() async {
  var client = XdgDesktopPortalClient();
  await client.close();
}
