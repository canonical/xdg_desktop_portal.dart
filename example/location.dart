import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void main(List<String> args) async {
  var client = XdgDesktopPortalClient();
  var locations = client.location.createSession();
  locations.listen((location) => print(location));
}
