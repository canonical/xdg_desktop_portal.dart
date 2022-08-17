import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void main(List<String> args) async {
  var client = XdgDesktopPortalClient();
  final screenCastStreams =
      await client.screenCast.createSession(multiple: true);
  for (final stream in screenCastStreams) {
    print(stream);
  }
  final fd = await client.screenCast.openPipeWireRemote();
  print(fd);
  await client.close();
}
