import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void main(List<String> args) async {
  var client = XdgDesktopPortalClient();
  var request = await client.email.composeEmail();
  if (await request.response != XdgPortalResponse.success) {
    print('Failed to compose email');
  }

  await client.close();
}
