import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void usage() {
  print('Usage:');
  print('  notification add <id> <title> <body>');
  print('  notification remove <id>');
}

void main(List<String> args) async {
  if (args.length < 2) {
    usage();
    return;
  }
  var command = args[0];
  var id = args[1];

  var client = XdgDesktopPortalClient();
  switch (command) {
    case 'add':
      if (args.length != 4) {
        usage();
      } else {
        var title = args[2];
        var body = args[3];
        await client.notification.addNotification(id, title: title, body: body);
      }
      break;
    case 'remove':
      await client.notification.removeNotification(id);
      break;
    default:
      usage();
      break;
  }

  await client.close();
}
