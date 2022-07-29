import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: open_uri <uri>');
    return;
  }
  var uri = args[0];

  var client = XdgDesktopPortalClient();
  await client.openUri.openUri(uri);

  await client.close();
}
