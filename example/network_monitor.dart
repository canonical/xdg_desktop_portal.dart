import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void usage() {
  print('Usage:');
  print('  network_monitor monitor');
  print('  network_monitor can-reach <hostname> <port>');
}

void main(List<String> args) async {
  if (args.isEmpty) {
    usage();
    return;
  }
  var action = args[0];

  if (action == 'monitor') {
    if (args.length != 1) {
      usage();
      return;
    }

    var client = XdgDesktopPortalClient();
    client.networkMonitor.status.listen((status) {
      print('Available: ${status.available}');
      if (status.available) {
        print('Metered: ${status.metered}');
        print('Connectivity: ${status.connectivity}');
      }
    });
  } else if (action == 'can-reach') {
    if (args.length < 3) {
      usage();
      return;
    }
    var hostname = args[1];
    var port = int.parse(args[2]);
    var client = XdgDesktopPortalClient();
    var canReach = await client.networkMonitor.canReach(hostname, port);
    await client.close();
    print('${canReach ? 'Can' : 'Cannot'} reach $hostname:$port');
  } else {
    print('Unknown action: $action');
    usage();
    return;
  }
}
