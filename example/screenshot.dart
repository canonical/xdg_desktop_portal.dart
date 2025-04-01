import 'package:collection/collection.dart';
import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void usage() {
  print('Usage: screenshot <window>');
  print('Options:');
  print('  -m, --modal');
  print('  -i, --interactive');
}

void main(List<String> args) async {
  var modal = args.contains('-m') || args.contains('--modal');
  var interactive = args.contains('-i') || args.contains('--interactive');
  var window = args.whereNot((a) => a.startsWith('-')).firstOrNull;
  if (window == null) {
    usage();
    return;
  }

  var client = XdgDesktopPortalClient();
  var result = await client.screenshot.screenshot(
    parentWindow: window,
    modal: modal,
    interactive: interactive,
  );
  print('Screenshot $window: $result');
  await client.close();
}
