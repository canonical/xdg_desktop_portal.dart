import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void main(List<String> args) async {
  var client = XdgDesktopPortalClient();
  await client.camera.accessCamera();
  final fd = await client.camera.openPipeWireRemote();
  print(fd);
  await client.close();
}
