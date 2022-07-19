import 'dart:io';
import 'dart:typed_data';

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
      case 'org.freedesktop.portal.Notification':
        return handleNotificationMethodCall(methodCall.name, methodCall.values);
      case 'org.freedesktop.portal.Settings':
        return handleSettingsMethodCall(methodCall.name, methodCall.values);
      default:
        return DBusMethodErrorResponse.unknownInterface();
    }
  }

  Future<DBusMethodResponse> handleNotificationMethodCall(
      String name, List<DBusValue> values) async {
    switch (name) {
      case 'AddNotification':
        var id = values[0].asString();
        var notification = values[1].asStringVariantDict();
        server.notifications[id] = notification;
        return DBusMethodSuccessResponse();
      case 'RemoveNotification':
        var id = values[0].asString();
        server.notifications.remove(id);
        return DBusMethodSuccessResponse();
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  Future<DBusMethodResponse> handleSettingsMethodCall(
      String name, List<DBusValue> values) async {
    switch (name) {
      case 'Read':
        var namespace = values[0].asString();
        var namespaceValues = server.settingsValues[namespace] ?? {};
        var key = values[1].asString();
        var value = namespaceValues[key];
        if (value == null) {
          return DBusMethodErrorResponse(
              'org.freedesktop.portal.Error.NotFound',
              [DBusString('Requested setting not found')]);
        }
        return DBusMethodSuccessResponse([DBusVariant(value)]);
      case 'ReadAll':
        var namespaces = values[0].asStringArray();
        var result = <DBusValue, DBusValue>{};
        for (var namespace in namespaces) {
          var settingsValues = server.settingsValues[namespace];
          if (settingsValues != null) {
            result[DBusString(namespace)] =
                DBusDict.stringVariant(settingsValues);
          }
        }
        return DBusMethodSuccessResponse(
            [DBusDict(DBusSignature('s'), DBusSignature('a{sv}'), result)]);
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }
}

class MockPortalServer extends DBusClient {
  late final MockPortalObject _root;
  late final Map<String, Map<String, DBusValue>> notifications;
  final Map<String, Map<String, DBusValue>> settingsValues;

  MockPortalServer(DBusAddress clientAddress,
      {Map<String, Map<String, DBusValue>>? notifications,
      this.settingsValues = const {}})
      : super(clientAddress) {
    _root = MockPortalObject(this);
    this.notifications = notifications ?? {};
  }

  Future<void> start() async {
    await requestName('org.freedesktop.portal.Desktop');
    await registerObject(_root);
  }
}

void main() {
  test('add notification', () async {
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

    await client.notification.addNotification('123',
        title: 'Title',
        body: 'Lorem Ipsum',
        priority: XdgNotificationPriority.high,
        defaultAction: 'action2',
        buttons: [
          XdgNotificationButton(label: 'Button 1', action: 'action1'),
          XdgNotificationButton(label: 'Button 2', action: 'action2')
        ]);
    expect(
        portalServer.notifications,
        equals({
          '123': {
            'title': DBusString('Title'),
            'body': DBusString('Lorem Ipsum'),
            'priority': DBusString('high'),
            'default-action': DBusString('action2'),
            'buttons': DBusArray(DBusSignature('a{sv}'), [
              DBusDict.stringVariant({
                'label': DBusString('Button 1'),
                'action': DBusString('action1')
              }),
              DBusDict.stringVariant({
                'label': DBusString('Button 2'),
                'action': DBusString('action2')
              })
            ])
          }
        }));
  });

  test('add notification - icon file', () async {
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

    await client.notification.addNotification('123',
        title: 'Title',
        icon: XdgNotificationIconFile('/usr/share/icons/icon.png'));
    expect(
        portalServer.notifications,
        equals({
          '123': {
            'title': DBusString('Title'),
            'icon': DBusStruct([
              DBusString('file'),
              DBusVariant(DBusString('/usr/share/icons/icon.png'))
            ])
          }
        }));
  });

  test('add notification - icon uri', () async {
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

    await client.notification.addNotification('123',
        title: 'Title',
        icon: XdgNotificationIconUri('https://example.com/icon.png'));
    expect(
        portalServer.notifications,
        equals({
          '123': {
            'title': DBusString('Title'),
            'icon': DBusStruct([
              DBusString('file'),
              DBusVariant(DBusString('https://example.com/icon.png'))
            ])
          }
        }));
  });

  test('add notification - icon themed', () async {
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

    await client.notification.addNotification('123',
        title: 'Title', icon: XdgNotificationIconThemed(['name', 'fallback']));
    expect(
        portalServer.notifications,
        equals({
          '123': {
            'title': DBusString('Title'),
            'icon': DBusStruct([
              DBusString('themed'),
              DBusVariant(DBusArray.string(['name', 'fallback']))
            ])
          }
        }));
  });

  test('add notification - icon data', () async {
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

    await client.notification.addNotification('123',
        title: 'Title',
        icon: XdgNotificationIconData(Uint8List.fromList(
            [0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef])));
    expect(
        portalServer.notifications,
        equals({
          '123': {
            'title': DBusString('Title'),
            'icon': DBusStruct([
              DBusString('bytes'),
              DBusVariant(DBusArray.byte(
                  [0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef]))
            ])
          }
        }));
  });

  test('remove notification', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalServer(clientAddress,
        notifications: {'122': {}, '123': {}, '124': {}});
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    await client.notification.removeNotification('123');
    expect(portalServer.notifications, equals({'122': {}, '124': {}}));
  });

  test('settings read', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalServer(clientAddress, settingsValues: {
      'com.example.test': {'name': DBusString('Fred')}
    });
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

  test('settings read all', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalServer(clientAddress, settingsValues: {
      'com.example.test1': {
        'name': DBusString('Fred'),
        'age': DBusUint32(42),
        'colour': DBusString('red')
      },
      'com.example.test2': {'name': DBusString('Bob')},
      'com.example.test3': {'name': DBusString('Alice'), 'age': DBusUint32(21)}
    });
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    expect(
        await client.settings
            .readAll(['com.example.test1', 'com.example.test3']),
        equals({
          'com.example.test1': {
            'name': DBusString('Fred'),
            'age': DBusUint32(42),
            'colour': DBusString('red')
          },
          'com.example.test3': {
            'name': DBusString('Alice'),
            'age': DBusUint32(21)
          }
        }));
  });
}
