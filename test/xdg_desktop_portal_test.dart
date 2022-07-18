import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:test/test.dart';
import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

class MockPortalObject extends DBusObject {
  final MockPortalServer server;

  MockPortalObject(this.server)
      : super(DBusObjectPath('/org/freedesktop/portal/desktop'));

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    switch (methodCall.interface) {
      case 'org.freedesktop.portal.Settings':
        return handleSettingsMethodCall(methodCall.name, methodCall.values);
      default:
        return DBusMethodErrorResponse.unknownInterface();
    }
  }

  Future<DBusMethodResponse> handleSettingsMethodCall(
      String name, List<DBusValue> values) async {
    switch (name) {
      case 'Read':
        var namespace = values[0].asString();
        var key = values[1].asString();
        var value = server.settingsValues['$namespace/$key'];
        if (value == null) {
          return DBusMethodErrorResponse(
              'org.freedesktop.portal.Error.NotFound',
              [DBusString('Requested setting not found')]);
        }
        return DBusMethodSuccessResponse([DBusVariant(value)]);
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }
}

class MockPortalServer extends DBusClient {
  late final MockPortalObject _root;
  final Map<String, DBusValue> settingsValues;

  MockPortalServer(DBusAddress clientAddress, {this.settingsValues = const {}})
      : super(clientAddress) {
    _root = MockPortalObject(this);
  }

  Future<void> start() async {
    await requestName('org.freedesktop.portal.Desktop');
    await registerObject(_root);
  }
}

void main() {
  test('settings read', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalServer(clientAddress,
        settingsValues: {'com.example.test/name': DBusString('Fred')});
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    expect(await client.settings.read('com.example.test', 'name'),
        equals(DBusString('Fred')));
  });
}
