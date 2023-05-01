import 'dart:io';

import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void usage() {
  print('Usage:');
  print('  notification add <id> <title> <body>');
  print('  notification remove <id>');
  print(
    '  notification monitor <id> <defaultAction> <button1Label> <button1Action> <button2Label> <button2Action>',
  );
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
    case 'monitor':
      if (args.length != 7) {
        usage();
        break;
      }
      client.notification.actionInvoked.listen((event) {
        print(event);
        exit(0);
      });
      var title = 'Example title';
      var body = 'Example body';
      await client.notification.addNotification(
        id,
        title: title,
        body: body,
        defaultAction: args[2],
        buttons: [
          XdgNotificationButton(
            label: args[3],
            action: args[4],
          ),
          XdgNotificationButton(
            label: args[5],
            action: args[6],
          ),
        ],
      );
      await Future.delayed(Duration(seconds: 5));
      break;
    default:
      usage();
      break;
  }

  await client.close();
}
