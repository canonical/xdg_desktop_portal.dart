import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void usage() {
  print('Usage:');
  print('  settings get <namespace> [<key>]');
  print('  settings monitor');
}

void main(List<String> args) async {
  if (args.isEmpty) {
    usage();
    return;
  }
  var command = args[0];

  var client = XdgDesktopPortalClient();
  switch (command) {
    case 'get':
      var namespace = args[1];
      if (args.length > 2) {
        var key = args[2];
        var value = await client.settings.read(namespace, key);
        print('${value.toNative()}');
      } else {
        var values = await client.settings.readAll([namespace]);
        for (var entry in (values[namespace] ?? {}).entries) {
          print('${entry.key}: ${entry.value.toNative()}');
        }
      }
      break;
    case 'monitor':
      await for (var value in client.settings.settingChanged) {
        print('${value.namespace}.${value.key} = ${value.value.toNative()}');
      }
      break;
    default:
      usage();
      break;
  }

  await client.close();
}
