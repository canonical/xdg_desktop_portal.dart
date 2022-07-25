import 'dart:math';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:dbus/dbus.dart';
import 'package:test/test.dart';
import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

class MockEmail {
  final String parentWindow;
  final Map<String, DBusValue> options;

  MockEmail(this.parentWindow, this.options);

  @override
  int get hashCode => Object.hash(parentWindow, options);

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    final mapEquals = const DeepCollectionEquality().equals;

    return other is MockEmail &&
        other.parentWindow == parentWindow &&
        mapEquals(other.options, options);
  }

  @override
  String toString() => '$runtimeType($parentWindow, $options)';
}

class MockUri {
  final String parentWindow;
  final String uri;
  final Map<String, DBusValue> options;

  MockUri(this.parentWindow, this.uri, this.options);

  @override
  int get hashCode => Object.hash(parentWindow, uri, options);

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    final mapEquals = const DeepCollectionEquality().equals;

    return other is MockUri &&
        other.parentWindow == parentWindow &&
        other.uri == uri &&
        mapEquals(other.options, options);
  }

  @override
  String toString() => '$runtimeType($parentWindow, $uri, $options)';
}

class MockPortalRequestObject extends DBusObject {
  final MockPortalServer server;
  var closed = false;

  MockPortalRequestObject(this.server, String sender, String token)
      : super(DBusObjectPath(
            '/org/freedesktop/portal/desktop/request/${sender.substring(1).replaceAll('.', '_')}/$token'));

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != 'org.freedesktop.impl.portal.Request') {
      return DBusMethodErrorResponse.unknownInterface();
    }

    if (methodCall.name == 'Close') {
      closed = true;
      return DBusMethodSuccessResponse();
    } else {
      return DBusMethodErrorResponse.unknownMethod();
    }
  }
}

class MockPortalObject extends DBusObject {
  final MockPortalServer server;

  MockPortalObject(this.server)
      : super(DBusObjectPath('/org/freedesktop/portal/desktop'));

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    switch (methodCall.interface) {
      case 'org.freedesktop.portal.Email':
        return handleEmailMethodCall(methodCall);
      case 'org.freedesktop.portal.Notification':
        return handleNotificationMethodCall(methodCall);
      case 'org.freedesktop.portal.OpenURI':
        return handleOpenURIMethodCall(methodCall);
      case 'org.freedesktop.portal.ProxyResolver':
        return handleProxyResolverMethodCall(methodCall);
      case 'org.freedesktop.portal.Settings':
        return handleSettingsMethodCall(methodCall);
      default:
        return DBusMethodErrorResponse.unknownInterface();
    }
  }

  Future<DBusMethodResponse> handleEmailMethodCall(
      DBusMethodCall methodCall) async {
    switch (methodCall.name) {
      case 'ComposeEmail':
        var parentWindow = methodCall.values[0].asString();
        var options = methodCall.values[1].asStringVariantDict();
        server.composedEmails.add(MockEmail(parentWindow, options));
        var token =
            options['handle_token']?.asString() ?? server.generateToken();
        options.removeWhere((key, value) => key == 'handle_token');
        var request = await server.addRequest(methodCall.sender, token);
        return DBusMethodSuccessResponse([request.path]);
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  Future<DBusMethodResponse> handleNotificationMethodCall(
      DBusMethodCall methodCall) async {
    switch (methodCall.name) {
      case 'AddNotification':
        var id = methodCall.values[0].asString();
        var notification = methodCall.values[1].asStringVariantDict();
        server.notifications[id] = notification;
        return DBusMethodSuccessResponse();
      case 'RemoveNotification':
        var id = methodCall.values[0].asString();
        server.notifications.remove(id);
        return DBusMethodSuccessResponse();
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  Future<DBusMethodResponse> handleOpenURIMethodCall(
      DBusMethodCall methodCall) async {
    switch (methodCall.name) {
      case 'OpenURI':
        var parentWindow = methodCall.values[0].asString();
        var uri = methodCall.values[1].asString();
        var options = methodCall.values[2].asStringVariantDict();
        var token =
            options['handle_token']?.asString() ?? server.generateToken();
        options.removeWhere((key, value) => key == 'handle_token');
        server.openedUris.add(MockUri(parentWindow, uri, options));
        var request = await server.addRequest(methodCall.sender, token);
        return DBusMethodSuccessResponse([request.path]);
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  Future<DBusMethodResponse> handleProxyResolverMethodCall(
      DBusMethodCall methodCall) async {
    switch (methodCall.name) {
      case 'Lookup':
        var uri = methodCall.values[0].asString();
        var proxies = server.proxies[uri] ?? ['direct://'];
        return DBusMethodSuccessResponse([DBusArray.string(proxies)]);
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  Future<DBusMethodResponse> handleSettingsMethodCall(
      DBusMethodCall methodCall) async {
    switch (methodCall.name) {
      case 'Read':
        var namespace = methodCall.values[0].asString();
        var namespaceValues = server.settingsValues[namespace] ?? {};
        var key = methodCall.values[1].asString();
        var value = namespaceValues[key];
        if (value == null) {
          return DBusMethodErrorResponse(
              'org.freedesktop.portal.Error.NotFound',
              [DBusString('Requested setting not found')]);
        }
        return DBusMethodSuccessResponse([DBusVariant(value)]);
      case 'ReadAll':
        var namespaces = methodCall.values[0].asStringArray();
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

  final requests = <MockPortalRequestObject>[];
  final usedTokens = <String>{};

  late final Map<String, Map<String, DBusValue>> notifications;
  final Map<String, List<String>> proxies;
  final Map<String, Map<String, DBusValue>> settingsValues;
  final composedEmails = <MockEmail>[];
  final openedUris = <MockUri>[];

  MockPortalServer(DBusAddress clientAddress,
      {Map<String, Map<String, DBusValue>>? notifications,
      this.proxies = const {},
      this.settingsValues = const {}})
      : super(clientAddress) {
    _root = MockPortalObject(this);
    this.notifications = notifications ?? {};
  }

  Future<void> start() async {
    await requestName('org.freedesktop.portal.Desktop');
    await registerObject(_root);
  }

  Future<MockPortalRequestObject> addRequest(
      String sender, String token) async {
    var object = MockPortalRequestObject(this, sender, token);
    await registerObject(object);
    return object;
  }

  /// Generate a token for requests and sessions.
  String generateToken() {
    final random = Random();
    String token;
    do {
      token = '${random.nextInt(1 << 32)}';
    } while (usedTokens.contains(token));
    usedTokens.add(token);
    return token;
  }
}

void main() {
  test('email', () async {
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

    await client.email.composeEmail(
        parentWindow: 'x11:12345',
        address: 'alice@example.com',
        addresses: ['bob@example.com', 'carol@example.com'],
        cc: ['dave@example.com'],
        bcc: ['elle@example.com'],
        subject: 'Great Opportunity',
        body: 'Would you like to buy some encyclopedias?');
    expect(
        portalServer.composedEmails,
        equals([
          MockEmail('x11:12345', {
            'address': DBusString('alice@example.com'),
            'addresses':
                DBusArray.string(['bob@example.com', 'carol@example.com']),
            'cc': DBusArray.string(['dave@example.com']),
            'bcc': DBusArray.string(['elle@example.com']),
            'subject': DBusString('Great Opportunity'),
            'body': DBusString('Would you like to buy some encyclopedias?')
          })
        ]));
  });

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

  test('open uri', () async {
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

    await client.openUri.openUri('http://example.com',
        parentWindow: 'x11:12345',
        writable: true,
        ask: true,
        activationToken: 'token');
    expect(
        portalServer.openedUris,
        equals([
          MockUri('x11:12345', 'http://example.com', {
            'writable': DBusBoolean(true),
            'ask': DBusBoolean(true),
            'activation_token': DBusString('token')
          })
        ]));
  });

  test('proxy resolver', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalServer(clientAddress, proxies: {
      'http://example.com': ['http://localhost:1234']
    });
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    expect(await client.proxyResolver.lookup('http://example.com'),
        equals(['http://localhost:1234']));
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
