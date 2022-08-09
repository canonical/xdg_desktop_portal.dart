import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void main(List<String> args) async {
  var client = XdgDesktopPortalClient();
  await client.email
      .composeEmail(address: 'dart@example.com', subject: 'Tell me about Dart');

  await client.close();
}
