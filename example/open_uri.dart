import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: open_uri <uri>');
    return;
  }
  var uri = args[0];

  var client = XdgDesktopPortalClient();
  var request = await client.openUri.openUri(uri);
  if (await request.response != XdgPortalResponse.success) {
    print('Failed to open URI');
  }

  await client.close();
}
