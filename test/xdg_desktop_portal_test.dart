import 'dart:async';
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
  int get hashCode => Object.hash(
      parentWindow,
      Object.hashAll(
          options.entries.map((entry) => Object.hash(entry.key, entry.value))));

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
  int get hashCode => Object.hash(
      parentWindow,
      uri,
      Object.hashAll(
          options.entries.map((entry) => Object.hash(entry.key, entry.value))));

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
  String toString() => '$runtimeType($uri, $options)';
}

class MockLocationSession {
  String? parentWindow;
  final Map<String, DBusValue> options;

  MockLocationSession(this.parentWindow, this.options);

  @override
  int get hashCode => Object.hash(
      parentWindow,
      Object.hashAll(
          options.entries.map((entry) => Object.hash(entry.key, entry.value))));

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    final mapEquals = const DeepCollectionEquality().equals;

    return other is MockLocationSession &&
        other.parentWindow == parentWindow &&
        mapEquals(other.options, options);
  }

  @override
  String toString() => '$runtimeType($parentWindow, $options)';
}

class MockPortalRequestObject extends DBusObject {
  final MockPortalServer server;

  MockPortalRequestObject(this.server, String sender, String token)
      : super(DBusObjectPath(
            '/org/freedesktop/portal/desktop/request/${sender.substring(1).replaceAll('.', '_')}/$token'));

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != 'org.freedesktop.portal.Request') {
      return DBusMethodErrorResponse.unknownInterface();
    }

    if (methodCall.name == 'Close') {
      await server.removeRequest(this);
      return DBusMethodSuccessResponse();
    } else {
      return DBusMethodErrorResponse.unknownMethod();
    }
  }

  Future<void> respond(
      {int response = 0, Map<String, DBusValue> result = const {}}) async {
    await emitSignal('org.freedesktop.portal.Request', 'Response',
        [DBusUint32(response), DBusDict.stringVariant(result)]);
    await server.removeRequest(this);
  }
}

class MockPortalSessionObject extends DBusObject {
  final MockPortalServer server;

  MockPortalSessionObject(this.server, String token)
      : super(DBusObjectPath('/org/freedesktop/portal/desktop/session/$token'));

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != 'org.freedesktop.portal.Session') {
      return DBusMethodErrorResponse.unknownInterface();
    }

    if (methodCall.name == 'Close') {
      await emitSignal('org.freedesktop.portal.Session', 'Closed');
      await server.removeSession(this);
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
      case 'org.freedesktop.portal.Location':
        return handleLocationMethodCall(methodCall);
      case 'org.freedesktop.portal.NetworkMonitor':
        return handleNetworkMonitorMethodCall(methodCall);
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
        Future.delayed(Duration.zero, () async => await request.respond());
        return DBusMethodSuccessResponse([request.path]);
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  Future<DBusMethodResponse> handleLocationMethodCall(
      DBusMethodCall methodCall) async {
    switch (methodCall.name) {
      case 'CreateSession':
        var options = methodCall.values[0].asStringVariantDict();
        var token = options['session_handle_token']?.asString();
        if (token == null) {
          return DBusMethodErrorResponse.invalidArgs('Missing token');
        }
        options.removeWhere((key, value) => key == 'session_handle_token');
        var locationSession = MockLocationSession(null, options);
        var session = await server.addSession(token);
        server._locationSessions[session.path] = locationSession;
        return DBusMethodSuccessResponse([session.path]);
      case 'Start':
        var path = methodCall.values[0].asObjectPath();
        var parentWindow = methodCall.values[1].asString();
        var locationSession = server._locationSessions[path];
        if (locationSession != null) {
          locationSession.parentWindow = parentWindow;
        }
        var options = methodCall.values[2].asStringVariantDict();
        var token =
            options['handle_token']?.asString() ?? server.generateToken();
        var request = await server.addRequest(methodCall.sender, token);
        Future.delayed(Duration.zero, () async => await request.respond());
        var location = <String, DBusValue>{};
        if (server.latitude != null) {
          location['Latitude'] = DBusDouble(server.latitude!);
        }
        if (server.longitude != null) {
          location['Longitude'] = DBusDouble(server.longitude!);
        }
        if (server.altitude != null) {
          location['Altitude'] = DBusDouble(server.altitude!);
        }
        if (server.accuracy != null) {
          location['Accuracy'] = DBusDouble(server.accuracy!);
        }
        if (server.speed != null) {
          location['Speed'] = DBusDouble(server.speed!);
        }
        if (server.heading != null) {
          location['Heading'] = DBusDouble(server.heading!);
        }
        if (server.locationTimestamp != null) {
          location['Timestamp'] = DBusStruct([
            DBusUint64(server.locationTimestamp! ~/ 1000000),
            DBusUint64(server.locationTimestamp! % 1000000)
          ]);
        }
        await emitSignal('org.freedesktop.portal.Location', 'LocationUpdated',
            [path, DBusDict.stringVariant(location)]);
        return DBusMethodSuccessResponse([request.path]);
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  Future<DBusMethodResponse> handleNetworkMonitorMethodCall(
      DBusMethodCall methodCall) async {
    switch (methodCall.name) {
      case 'GetStatus':
        var status = <String, DBusValue>{};
        status['available'] = DBusBoolean(server.networkAvailable);
        status['metered'] = DBusBoolean(server.networkMetered);
        status['connectivity'] = DBusUint32(server.networkConnectivity);
        return DBusMethodSuccessResponse([DBusDict.stringVariant(status)]);
      case 'CanReach':
        var hostname = methodCall.values[0].asString();
        var port = methodCall.values[1].asUint32();
        var canReach = true;
        if (hostname == 'unreachable.com' && port == 99) {
          canReach = false;
        }
        return DBusMethodSuccessResponse([DBusBoolean(canReach)]);
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
        Future.delayed(Duration.zero, () async => await request.respond());
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
  final sessions = <MockPortalSessionObject>[];
  final usedTokens = <String>{};

  late final Map<String, Map<String, DBusValue>> notifications;
  final Map<String, List<String>> proxies;
  final Map<String, Map<String, DBusValue>> settingsValues;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final int? locationTimestamp;
  bool networkAvailable;
  bool networkMetered;
  int networkConnectivity;

  final composedEmails = <MockEmail>[];
  final openedUris = <MockUri>[];
  Iterable<MockLocationSession> get locationSessions =>
      _locationSessions.values;
  final _locationSessions = <DBusObjectPath, MockLocationSession>{};

  MockPortalServer(DBusAddress clientAddress,
      {Map<String, Map<String, DBusValue>>? notifications,
      this.proxies = const {},
      this.settingsValues = const {},
      this.latitude,
      this.longitude,
      this.altitude,
      this.accuracy,
      this.speed,
      this.heading,
      this.locationTimestamp,
      this.networkAvailable = true,
      this.networkMetered = false,
      this.networkConnectivity = 3})
      : super(clientAddress) {
    _root = MockPortalObject(this);
    this.notifications = notifications ?? {};
  }

  Future<void> start() async {
    await requestName('org.freedesktop.portal.Desktop');
    await registerObject(_root);
  }

  Future<void> setNetworkStatus(
      {bool? available, bool? metered, int? connectivity}) async {
    if (available != null) {
      networkAvailable = available;
    }
    if (metered != null) {
      networkMetered = metered;
    }
    if (connectivity != null) {
      networkConnectivity = connectivity;
    }
    await _root.emitSignal('org.freedesktop.portal.NetworkMonitor', 'changed');
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

  Future<MockPortalRequestObject> addRequest(
      String sender, String token) async {
    var request = MockPortalRequestObject(this, sender, token);
    await registerObject(request);
    return request;
  }

  Future<void> removeRequest(MockPortalRequestObject request) async {
    requests.remove(request);
    await unregisterObject(request);
  }

  Future<MockPortalSessionObject> addSession(String token) async {
    var session = MockPortalSessionObject(this, token);
    sessions.add(session);
    await registerObject(session);
    return session;
  }

  Future<void> removeSession(MockPortalSessionObject session) async {
    sessions.remove(session);
    await unregisterObject(session);
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

  test('location', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalServer(clientAddress,
        latitude: 40.9,
        longitude: 174.9,
        altitude: 42.0,
        accuracy: 1.2,
        speed: 28,
        heading: 321.4,
        locationTimestamp: 1658718568000000);
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    var locations = client.location.createSession(
        distanceThreshold: 1,
        timeThreshold: 10,
        accuracy: XdgLocationAccuracy.street,
        parentWindow: 'x11:12345');
    locations.listen(expectAsync1((location) {
      expect(
          location,
          equals(XdgLocation(
              latitude: 40.9,
              longitude: 174.9,
              altitude: 42.0,
              accuracy: 1.2,
              speed: 28.0,
              heading: 321.4,
              timestamp:
                  DateTime.fromMicrosecondsSinceEpoch(1658718568000000))));
      expect(
          location.hashCode,
          equals(XdgLocation(
                  latitude: 40.9,
                  longitude: 174.9,
                  altitude: 42.0,
                  accuracy: 1.2,
                  speed: 28.0,
                  heading: 321.4,
                  timestamp:
                      DateTime.fromMicrosecondsSinceEpoch(1658718568000000))
              .hashCode));
      expect(
          location.toString(),
          equals(
              'XdgLocation(latitude: 40.9, longitude: 174.9, altitude: 42.0, accuracy: 1.2, speed: 28.0, heading: 321.4, timestamp: 2022-07-25 03:09:28.000Z)'));
      expect(
          portalServer.locationSessions,
          equals([
            MockLocationSession('x11:12345', {
              'distance-threshold': DBusUint32(1),
              'time-threshold': DBusUint32(10),
              'accuracy': DBusUint32(4)
            })
          ]));
    }));
  });

  test('location - cancel', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalServer(clientAddress,
        latitude: 40.9,
        longitude: 174.9,
        altitude: 42.0,
        accuracy: 1.2,
        speed: 28,
        heading: 321.4,
        locationTimestamp: 1658718568000000);
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var busClient = DBusClient(clientAddress);
    var client = XdgDesktopPortalClient(bus: busClient);
    addTearDown(() async {
      await client.close();
    });

    expect(portalServer.sessions, isEmpty);
    var locations = client.location.createSession(
        distanceThreshold: 1,
        timeThreshold: 10,
        accuracy: XdgLocationAccuracy.street,
        parentWindow: 'x11:12345');
    var locationCompleter = Completer();
    var s = locations.listen((location) async {
      locationCompleter.complete();
    });

    // Ensure that the session has been created and then check for it.
    await busClient.ping();
    expect(portalServer.sessions, hasLength(1));

    /// Once get the first location, cancel the stream which should end the session.
    await locationCompleter.future;
    await s.cancel();
    expect(portalServer.sessions, isEmpty);
  });

  test('network monitor - status', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalServer(clientAddress,
        networkAvailable: true, networkMetered: true, networkConnectivity: 0);
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var busClient = DBusClient(clientAddress);
    var client = XdgDesktopPortalClient(bus: busClient);
    addTearDown(() async {
      await client.close();
    });

    expect(
        client.networkMonitor.status,
        emitsInOrder([
          XdgNetworkStatus(
              available: true,
              metered: true,
              connectivity: XdgNetworkConnectivity.local),
          XdgNetworkStatus(
              available: false,
              metered: false,
              connectivity: XdgNetworkConnectivity.full),
        ]));

    // Ensure that the first value has been retrieved.
    await busClient.ping();

    await portalServer.setNetworkStatus(
        available: false, metered: false, connectivity: 3);
  });

  test('network monitor - can reach', () async {
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

    expect(await client.networkMonitor.canReach('example.com', 80), isTrue);
    expect(
        await client.networkMonitor.canReach('unreachable.com', 99), isFalse);
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
