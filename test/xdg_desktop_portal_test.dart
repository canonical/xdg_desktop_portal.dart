import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:test/test.dart';
import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

class MockPortalObject extends DBusObject {
  final MockPortalServer server;

  MockPortalObject(this.server)
      : super(DBusObjectPath('/org/freedesktop/portal/desktop'));
}

class MockPortalServer extends DBusClient {
  late final MockPortalObject _root;

  MockPortalServer(DBusAddress clientAddress) : super(clientAddress) {
    _root = MockPortalObject(this);
  }

  Future<void> start() async {
    await requestName('org.freedesktop.portal.Desktop');
    await registerObject(_root);
  }
}

void main() {
  test('FIXME', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalServer(clientAddress);
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });
  });
}
