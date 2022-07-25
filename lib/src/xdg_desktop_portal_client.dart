import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:dbus/dbus.dart';

/// A request sent to a portal.
class XdgPortalRequest {
  /// The client that is connected to this portal.
  XdgDesktopPortalClient client;

  late final DBusRemoteObject _object;

  XdgPortalRequest(this.client, DBusObjectPath path) {
    _object =
        DBusRemoteObject(client._bus, name: client._object.name, path: path);
  }

  /// Ends the user interaction with this request.
  Future<void> close() async {
    await _object.callMethod('org.freedesktop.impl.portal.Request', 'Close', [],
        replySignature: DBusSignature(''));
  }
}

/// A session opened on a portal.
class XdgPortalSession {
  /// The client that is connected to this portal.
  XdgDesktopPortalClient client;

  /// true when this session has been closed by the portal.
  final _closedCompleter = Completer<bool>();
  Future<bool> get closed => _closedCompleter.future;

  late final DBusRemoteObject _object;

  XdgPortalSession(this.client, DBusObjectPath path) {
    _object =
        DBusRemoteObject(client._bus, name: client._object.name, path: path);
  }

  /// Close the session.
  Future<void> close() async {
    await _object.callMethod('org.freedesktop.impl.portal.Session', 'Close', [],
        replySignature: DBusSignature(''));
  }
}

/// Portal to send email.
class XdgEmailPortal {
  /// The client that is connected to this portal.
  XdgDesktopPortalClient client;

  XdgEmailPortal(this.client);

  /// Present a window to compose an email.
  Future<XdgPortalRequest> composeEmail(
      {String parentWindow = '',
      String? address,
      Iterable<String> addresses = const [],
      Iterable<String> cc = const [],
      Iterable<String> bcc = const [],
      String? subject,
      String? body}) async {
    var options = <String, DBusValue>{};
    options['handle_token'] = DBusString(client._generateToken());
    if (address != null) {
      options['address'] = DBusString(address);
    }
    if (addresses.isNotEmpty) {
      options['addresses'] = DBusArray.string(addresses);
    }
    if (cc.isNotEmpty) {
      options['cc'] = DBusArray.string(cc);
    }
    if (bcc.isNotEmpty) {
      options['bcc'] = DBusArray.string(bcc);
    }
    if (subject != null) {
      options['subject'] = DBusString(subject);
    }
    if (body != null) {
      options['body'] = DBusString(body);
    }
    var result = await client._object.callMethod(
        'org.freedesktop.portal.Email',
        'ComposeEmail',
        [DBusString(parentWindow), DBusDict.stringVariant(options)],
        replySignature: DBusSignature('o'));
    return XdgPortalRequest(client, result.returnValues[0].asObjectPath());
  }
}

/// Network connectivity states.
enum XdgNetworkConnectivity { local, limited, portal, full }

class XdgNetworkStatus {
  /// true if the network is available.
  bool available;

  /// true if the network is metered.
  bool metered;

  /// The network connectivity state.
  XdgNetworkConnectivity connectivity;

  XdgNetworkStatus(
      {required this.available,
      required this.metered,
      required this.connectivity});

  @override
  int get hashCode => Object.hash(available, metered, connectivity);

  @override
  bool operator ==(other) =>
      other is XdgNetworkStatus &&
      other.available == available &&
      other.metered == metered &&
      other.connectivity == connectivity;

  @override
  String toString() =>
      '$runtimeType(available: $available, metered: $metered, connectivity: $connectivity)';
}

/// Portal to monitor networking.
class XdgNetworkMonitorPortal {
  /// The client that is connected to this portal.
  XdgDesktopPortalClient client;

  /// Stream of events when the status changes.
  Stream<void> get changed => DBusRemoteObjectSignalStream(
          object: client._object,
          interface: 'org.freedesktop.portal.NetworkMonitor',
          name: 'changed',
          signature: DBusSignature(''))
      .map((signal) {});

  XdgNetworkMonitorPortal(this.client);

  /// Get the current status of the network.
  Future<XdgNetworkStatus> getStatus() async {
    var result = await client._object.callMethod(
        'org.freedesktop.portal.NetworkMonitor', 'GetStatus', [],
        replySignature: DBusSignature('a{sv}'));
    var options = result.returnValues[0].asStringVariantDict();
    var available = false;
    var availableValue = options['available'];
    if (availableValue != null && availableValue is DBusBoolean) {
      available = availableValue.asBoolean();
    }
    var metered = false;
    var meteredValue = options['metered'];
    if (meteredValue != null && meteredValue is DBusBoolean) {
      metered = meteredValue.asBoolean();
    }
    var connectivity = XdgNetworkConnectivity.full;
    var connectivityValue = options['connectivity'];
    if (connectivityValue != null && connectivityValue is DBusUint32) {
      connectivity = {
            0: XdgNetworkConnectivity.local,
            1: XdgNetworkConnectivity.limited,
            2: XdgNetworkConnectivity.portal,
            3: XdgNetworkConnectivity.full
          }[connectivityValue.asUint32()] ??
          XdgNetworkConnectivity.full;
    }
    return XdgNetworkStatus(
        available: available, metered: metered, connectivity: connectivity);
  }

  /// Returns true if the given [hostname]:[port] is believed to be reachable.
  Future<bool> canReach(String hostname, int port) async {
    var result = await client._object.callMethod(
        'org.freedesktop.portal.NetworkMonitor',
        'CanReach',
        [DBusString(hostname), DBusUint32(port)],
        replySignature: DBusSignature('b'));
    return result.returnValues[0].asBoolean();
  }
}

/// Priorities for notifications.
enum XdgNotificationPriority { low, normal, high, urgent }

/// An icon to be shown in a notification.
abstract class XdgNotificationIcon {}

/// An icon stored in the file system.
class XdgNotificationIconFile extends XdgNotificationIcon {
  /// Path of this icon
  final String path;

  XdgNotificationIconFile(this.path);
}

/// An icon at a URI.
class XdgNotificationIconUri extends XdgNotificationIcon {
  /// Uri of this icon
  final String uri;

  XdgNotificationIconUri(this.uri);
}

/// A themed icon.
class XdgNotificationIconThemed extends XdgNotificationIcon {
  /// Theme names to lookup for this icon in order of priority.
  final List<String> names;

  XdgNotificationIconThemed(this.names);
}

/// An icon with image data.
class XdgNotificationIconData extends XdgNotificationIcon {
  /// Image data for this icon.
  final Uint8List data;

  XdgNotificationIconData(this.data);
}

/// A button to be shown in a notification.
class XdgNotificationButton {
  /// Label on this button.
  final String label;

  /// Action to perform with this button.
  final String action;

  XdgNotificationButton({required this.label, required this.action});
}

/// Portal to create notifications.
class XdgNotificationPortal {
  /// The client that is connected to this portal.
  XdgDesktopPortalClient client;

  XdgNotificationPortal(this.client);

  /// Send a notification.
  /// [id] can be used later to withdraw the notification with [removeNotification].
  /// If [id] is reused without withdrawing, the existing notification is replaced.
  Future<void> addNotification(String id,
      {String? title,
      String? body,
      XdgNotificationIcon? icon,
      XdgNotificationPriority? priority,
      String? defaultAction,
      List<XdgNotificationButton> buttons = const []}) async {
    var notification = <String, DBusValue>{};
    if (title != null) {
      notification['title'] = DBusString(title);
    }
    if (body != null) {
      notification['body'] = DBusString(body);
    }
    if (icon != null) {
      if (icon is XdgNotificationIconFile) {
        notification['icon'] = DBusStruct(
            [DBusString('file'), DBusVariant(DBusString(icon.path))]);
      } else if (icon is XdgNotificationIconUri) {
        notification['icon'] =
            DBusStruct([DBusString('file'), DBusVariant(DBusString(icon.uri))]);
      } else if (icon is XdgNotificationIconThemed) {
        notification['icon'] = DBusStruct(
            [DBusString('themed'), DBusVariant(DBusArray.string(icon.names))]);
      } else if (icon is XdgNotificationIconData) {
        notification['icon'] = DBusStruct(
            [DBusString('bytes'), DBusVariant(DBusArray.byte(icon.data))]);
      }
    }
    if (priority != null) {
      notification['priority'] = DBusString({
            XdgNotificationPriority.low: 'low',
            XdgNotificationPriority.normal: 'normal',
            XdgNotificationPriority.high: 'high',
            XdgNotificationPriority.urgent: 'urgent'
          }[priority] ??
          'normal');
    }
    if (defaultAction != null) {
      notification['default-action'] = DBusString(defaultAction);
    }
    if (buttons.isNotEmpty) {
      notification['buttons'] =
          DBusArray(DBusSignature('a{sv}'), buttons.map((button) {
        var values = {
          'label': DBusString(button.label),
          'action': DBusString(button.action)
        };
        return DBusDict.stringVariant(values);
      }));
    }
    await client._object.callMethod(
        'org.freedesktop.portal.Notification',
        'AddNotification',
        [DBusString(id), DBusDict.stringVariant(notification)],
        replySignature: DBusSignature(''));
  }

  /// Withdraw a notification created with [addNotification].
  Future<void> removeNotification(String id) async {
    await client._object.callMethod('org.freedesktop.portal.Notification',
        'RemoveNotification', [DBusString(id)],
        replySignature: DBusSignature(''));
  }
}

/// Requested accuracy of location information.
enum XdgLocationAccuracy { none, country, city, neighborhood, street, exact }

/// Location information.
class XdgLocation {
  // The latitude, in degrees.
  final double? latitude;

  // The longitude, in degrees.
  final double? longitude;

  // The altitude, in meters.
  final double? altitude;

  /// The accuracy, in meters.
  final double? accuracy;

  /// The speed, in meters per second.
  final double? speed;

  /// The heading, in degrees, going clockwise. North 0, East 90, South 180, West 270.
  final double? heading;

  /// Time time this location was recorded.
  final DateTime? timestamp;

  XdgLocation(
      {this.latitude,
      this.longitude,
      this.altitude,
      this.accuracy,
      this.speed,
      this.heading,
      this.timestamp});

  @override
  int get hashCode => Object.hash(
      latitude, longitude, altitude, accuracy, speed, heading, timestamp);

  @override
  bool operator ==(other) =>
      other is XdgLocation &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.altitude == altitude &&
      other.accuracy == accuracy &&
      other.speed == speed &&
      other.heading == heading &&
      other.timestamp == timestamp;

  @override
  String toString() =>
      '$runtimeType(latitude: $latitude, longitude: $longitude, altitude: $altitude, accuracy: $accuracy, speed: $speed, heading: $heading, timestamp: $timestamp)';
}

/// A location session.
class XdgLocationSession extends XdgPortalSession {
  final _locationUpdated = StreamController<XdgLocation>();

  /// Stream of location updates from the portal.
  Stream<XdgLocation> get locationUpdated => _locationUpdated.stream;

  XdgLocationSession(XdgDesktopPortalClient client, DBusObjectPath path)
      : super(client, path);

  /// Start this session.
  Future<XdgPortalRequest> start({String parentWindow = ''}) async {
    var options = <String, DBusValue>{};
    var result = await client._object.callMethod(
        'org.freedesktop.portal.Location',
        'Start',
        [
          _object.path,
          DBusString(parentWindow),
          DBusDict.stringVariant(options)
        ],
        replySignature: DBusSignature('o'));
    var handle = result.returnValues[0].asObjectPath();
    return XdgPortalRequest(client, handle);
  }
}

/// Portal to get location information.
class XdgLocationPortal {
  /// The client that is connected to this portal.
  XdgDesktopPortalClient client;

  late final StreamSubscription _locationUpdatedSubscription;

  XdgLocationPortal(this.client) {
    var locationUpdated = DBusSignalStream(client._bus,
        interface: 'org.freedesktop.portal.Location',
        name: 'LocationUpdated',
        path: client._object.path,
        signature: DBusSignature('oa{sv}'));
    _locationUpdatedSubscription = locationUpdated.listen((signal) {
      var path = signal.values[0].asObjectPath();
      var session = client._sessions[path];
      if (session == null || session is! XdgLocationSession) {
        return;
      }
      var location = signal.values[1].asStringVariantDict();
      double? getLocationValue(String name) {
        var value = location[name];
        if (value == null || value is! DBusDouble) {
          return null;
        }
        return value.asDouble();
      }

      DateTime? timestamp;
      var timestampValue = location['Timestamp'];
      if (timestampValue != null &&
          timestampValue.signature == DBusSignature('(tt)')) {
        var values = timestampValue.asStruct();
        var s = values[0].asUint64();
        var us = values[1].asUint64();
        timestamp = DateTime.fromMicrosecondsSinceEpoch(s * 1000000 + us);
      }

      session._locationUpdated.add(XdgLocation(
          latitude: getLocationValue('Latitude'),
          longitude: getLocationValue('Longitude'),
          altitude: getLocationValue('Altitude'),
          accuracy: getLocationValue('Accuracy'),
          speed: getLocationValue('Speed'),
          heading: getLocationValue('Heading'),
          timestamp: timestamp));
    });
  }

  /// Create a location session.
  Future<XdgLocationSession> createSession(
      {int? distanceThreshold,
      int? timeThreshold,
      XdgLocationAccuracy? accuracy}) async {
    var options = <String, DBusValue>{};
    options['session_handle_token'] = DBusString(client._generateToken());
    if (distanceThreshold != null) {
      options['distance-threshold'] = DBusUint32(distanceThreshold);
    }
    if (timeThreshold != null) {
      options['time-threshold'] = DBusUint32(timeThreshold);
    }
    if (accuracy != null) {
      options['accuracy'] = DBusUint32({
            XdgLocationAccuracy.none: 0,
            XdgLocationAccuracy.country: 1,
            XdgLocationAccuracy.city: 2,
            XdgLocationAccuracy.neighborhood: 3,
            XdgLocationAccuracy.street: 4,
            XdgLocationAccuracy.exact: 5
          }[accuracy] ??
          5);
    }
    var result = await client._object.callMethod(
        'org.freedesktop.portal.Location',
        'CreateSession',
        [DBusDict.stringVariant(options)],
        replySignature: DBusSignature('o'));
    var session =
        XdgLocationSession(client, result.returnValues[0].asObjectPath());
    client._addSession(session);
    return session;
  }

  Future<void> _close() async {
    await _locationUpdatedSubscription.cancel();
  }
}

/// Portal to open URIs.
class XdgOpenUriPortal {
  /// The client that is connected to this portal.
  XdgDesktopPortalClient client;

  XdgOpenUriPortal(this.client);

  /// Ask to open a URI.
  Future<XdgPortalRequest> openUri(String uri,
      {String parentWindow = '',
      bool? writable,
      bool? ask,
      String? activationToken}) async {
    var options = <String, DBusValue>{};
    options['handle_token'] = DBusString(client._generateToken());
    if (writable != null) {
      options['writable'] = DBusBoolean(writable);
    }
    if (ask != null) {
      options['ask'] = DBusBoolean(ask);
    }
    if (activationToken != null) {
      options['activation_token'] = DBusString(activationToken);
    }
    var result = await client._object.callMethod(
        'org.freedesktop.portal.OpenURI',
        'OpenURI',
        [
          DBusString(parentWindow),
          DBusString(uri),
          DBusDict.stringVariant(options)
        ],
        replySignature: DBusSignature('o'));
    return XdgPortalRequest(client, result.returnValues[0].asObjectPath());
  }

  // FIXME: OpenFile

  // FIXME: OpenDirectory
}

/// Portal to use system proxy.
class XdgProxyResolverPortal {
  /// The client that is connected to this portal.
  XdgDesktopPortalClient client;

  XdgProxyResolverPortal(this.client);

  /// Looks up which proxy to use to connect to [uri].
  /// 'direct://' is returned when no proxy is needed.
  Future<List<String>> lookup(String uri) async {
    var result = await client._object.callMethod(
        'org.freedesktop.portal.ProxyResolver', 'Lookup', [DBusString(uri)],
        replySignature: DBusSignature('as'));
    return result.returnValues[0].asStringArray().toList();
  }
}

/// Portal to access system settings.
class XdgSettingsPortal {
  /// The client that is connected to this portal.
  XdgDesktopPortalClient client;

  XdgSettingsPortal(this.client);

  /// Read a single value.
  Future<DBusValue> read(String namespace, String key) async {
    var result = await client._object.callMethod(
        'org.freedesktop.portal.Settings',
        'Read',
        [DBusString(namespace), DBusString(key)],
        replySignature: DBusSignature('v'));
    return result.returnValues[0].asVariant();
  }

  /// Read all the the settings in the given [namespaces].
  /// Globbing is allowed on trailing sections, e.g. 'com.example.*'.
  Future<Map<String, Map<String, DBusValue>>> readAll(
      Iterable<String> namespaces) async {
    var result = await client._object.callMethod(
        'org.freedesktop.portal.Settings',
        'ReadAll',
        [DBusArray.string(namespaces)],
        replySignature: DBusSignature('a{sa{sv}}'));
    return result.returnValues[0].asDict().map(
        (key, value) => MapEntry(key.asString(), value.asStringVariantDict()));
  }
}

/// A client that connects to the portals.
class XdgDesktopPortalClient {
  /// The bus this client is connected to.
  final DBusClient _bus;
  final bool _closeBus;

  late final DBusRemoteObject _object;

  late final StreamSubscription _sessionClosedSubscription;

  final _sessions = <DBusObjectPath, XdgPortalSession>{};

  /// Portal to send email.
  late final XdgEmailPortal email;

  /// Portal to get location information.
  late final XdgLocationPortal location;

  /// Portal to monitor networking.
  late final XdgNetworkMonitorPortal networkMonitor;

  /// Portal to create notifications.
  late final XdgNotificationPortal notification;

  /// Portal to open URIs.
  late final XdgOpenUriPortal openUri;

  /// Portal to use system proxy.
  late final XdgProxyResolverPortal proxyResolver;

  /// Portal to access system settings.
  late final XdgSettingsPortal settings;

  /// Keep track of used request/session tokens.
  final _usedTokens = <String>{};

  /// Creates a new portal client. If [bus] is provided connect to the given D-Bus server.
  XdgDesktopPortalClient({DBusClient? bus})
      : _bus = bus ?? DBusClient.session(),
        _closeBus = bus == null {
    _object = DBusRemoteObject(_bus,
        name: 'org.freedesktop.portal.Desktop',
        path: DBusObjectPath('/org/freedesktop/portal/desktop'));
    var sessionClosed = DBusSignalStream(_bus,
        interface: 'org.freedesktop.impl.portal.Session',
        name: 'Closed',
        signature: DBusSignature(''));
    _sessionClosedSubscription = sessionClosed.listen((signal) {
      var session = _sessions[signal.path];
      if (session != null) {
        session._closedCompleter.complete(true);
      }
    });
    email = XdgEmailPortal(this);
    location = XdgLocationPortal(this);
    networkMonitor = XdgNetworkMonitorPortal(this);
    notification = XdgNotificationPortal(this);
    openUri = XdgOpenUriPortal(this);
    proxyResolver = XdgProxyResolverPortal(this);
    settings = XdgSettingsPortal(this);
  }

  /// Terminates all active connections. If a client remains unclosed, the Dart process may not terminate.
  Future<void> close() async {
    await _sessionClosedSubscription.cancel();
    await location._close();
    if (_closeBus) {
      await _bus.close();
    }
  }

  /// Generate a token for requests and sessions.
  String _generateToken() {
    final random = Random();
    String token;
    do {
      token = 'dart${random.nextInt(1 << 32)}';
    } while (_usedTokens.contains(token));
    _usedTokens.add(token);
    return token;
  }

  /// Record an active portal session.
  XdgPortalSession _addSession(XdgPortalSession session) {
    _sessions[session._object.path] = session;
    return session;
  }
}
