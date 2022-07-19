import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage proxy_resolver <uri>');
    return;
  }
  var uri = args[0];

  var client = XdgDesktopPortalClient();
  var proxies = await client.proxyResolver.lookup(uri);
  for (var proxy in proxies) {
    print(proxy);
  }

  await client.close();
}
