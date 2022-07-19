import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage settings <namespace> [<key>]');
    return;
  }
  var namespace = args[0];

  var client = XdgDesktopPortalClient();
  if (args.length > 1) {
    var key = args[1];
    var value = await client.settings.read(namespace, key);
    print('${value.toNative()}');
  } else {
    var values = await client.settings.readAll([namespace]);
    for (var entry in (values[namespace] ?? {}).entries) {
      print('${entry.key}: ${entry.value.toNative()}');
    }
  }

  await client.close();
}
