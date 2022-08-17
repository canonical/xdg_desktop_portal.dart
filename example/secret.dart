import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void main(List<String> args) async {
  var client = XdgDesktopPortalClient();
  final secret = await client.secret.retrieveSecret();
  print('Secret: $secret');
  await client.close();
}
