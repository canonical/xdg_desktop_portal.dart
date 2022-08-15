import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void main(List<String> args) async {
  var client = XdgDesktopPortalClient();
  print('createSession');
  await client.screenCast.createSession();
  print('selectSources');
  await client.screenCast.selectSources(
    sourceTypes: {ScreenCastAvailableSourceTypes.monitor},
    cursorModes: {ScreenCastAvailableCursorModes.hidden},
  );
  print('start');
  await client.screenCast.start();
  print('openPipeWireRemote');
  final fd = await client.screenCast.openPipeWireRemote();
  print(fd);
  await client.screenCast.close();
}
