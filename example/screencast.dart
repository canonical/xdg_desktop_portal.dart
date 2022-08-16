import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void main(List<String> args) async {
  var client = XdgDesktopPortalClient();
  await client.screenCast.createSession();
  await client.screenCast.selectSources(multiple: true);
  final screenCastStreams = await client.screenCast.start();
  for (final stream in screenCastStreams) {
    print(stream);
  }
  final fd = await client.screenCast.openPipeWireRemote();
  print(fd);
  await client.close();
}
