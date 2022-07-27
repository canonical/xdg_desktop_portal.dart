import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void main(List<String> args) async {
  var client = XdgDesktopPortalClient();
  var session = await client.location.createSession();
  session.locationUpdated.listen((location) => print(location));
  var request = await session.start();
  if (await request.response != XdgPortalResponse.success) {
    print('Failed to get location');
  }
}
