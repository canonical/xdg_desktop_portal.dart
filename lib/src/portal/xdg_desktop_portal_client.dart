import 'dart:async';
import 'dart:math';

import 'package:dbus/dbus.dart';

import 'xdg_portal_request.dart';
import 'xdg_portal_response.dart';
import 'xdg_portal_session.dart';
import 'xdg_portals.dart';

/// A client that connects to the portals.
class XdgDesktopPortalClient {
  /// The bus this client is connected to.
  final DBusClient _bus;
  final bool _closeBus;

  late final DBusRemoteObject _object;

  late final StreamSubscription _requestResponseSubscription;
  late final StreamSubscription _sessionClosedSubscription;

  final _requests = <DBusObjectPath, XdgPortalRequest>{};
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
    _object = DBusRemoteObject(
      _bus,
      name: 'org.freedesktop.portal.Desktop',
      path: DBusObjectPath('/org/freedesktop/portal/desktop'),
    );
    var requestResponse = DBusSignalStream(
      _bus,
      interface: 'org.freedesktop.portal.Request',
      name: 'Response',
      signature: DBusSignature('ua{sv}'),
    );
    _requestResponseSubscription = requestResponse.listen(
      (signal) {
        var request = _requests.remove(signal.path);
        if (request != null) {
          request.handleResponse(
            {
                  0: XdgPortalResponse.success,
                  1: XdgPortalResponse.cancelled,
                  2: XdgPortalResponse.other
                }[signal.values[0].asUint32()] ??
                XdgPortalResponse.other,
            signal.values[1].asStringVariantDict(),
          );
        }
      },
    );
    var sessionClosed = DBusSignalStream(
      _bus,
      interface: 'org.freedesktop.portal.Session',
      name: 'Closed',
      signature: DBusSignature(''),
    );
    _sessionClosedSubscription = sessionClosed.listen(
      (signal) {
        var session = _sessions.remove(signal.path);
        if (session != null) {
          session.handleClosed();
        }
      },
    );
    email = XdgEmailPortal(this);
    location = XdgLocationPortal(this);
    networkMonitor = XdgNetworkMonitorPortal(this);
    notification = XdgNotificationPortal(this);
    openUri = XdgOpenUriPortal(this);
    proxyResolver = XdgProxyResolverPortal(this);
    settings = XdgSettingsPortal(this);
  }

  DBusClient get bus => _bus;
  String get name => _object.name;
  DBusObjectPath get path => _object.path;
  DBusRemoteObject get object => _object;
  Map<DBusObjectPath, XdgPortalSession> get sessions => _sessions;

  /// Terminates all active connections. If a client remains unclosed, the Dart process may not terminate.
  Future<void> close() async {
    await _requestResponseSubscription.cancel();
    await _sessionClosedSubscription.cancel();
    await location.close();
    await networkMonitor.close();
    if (_closeBus) {
      await _bus.close();
    }
  }

  /// Generate a token for requests and sessions.
  String generateToken() {
    final random = Random();
    String token;
    do {
      token = 'dart${random.nextInt(1 << 32)}';
    } while (_usedTokens.contains(token));
    _usedTokens.add(token);
    return token;
  }

  Future<DBusMethodSuccessResponse> callMethod(
    String? interface,
    String name,
    Iterable<DBusValue> values, {
    DBusSignature? replySignature,
    bool noReplyExpected = false,
    bool noAutoStart = false,
    bool allowInteractiveAuthorization = false,
  }) async {
    return _object.callMethod(
      interface,
      name,
      values,
      replySignature: replySignature,
      noReplyExpected: noReplyExpected,
      noAutoStart: noAutoStart,
      allowInteractiveAuthorization: allowInteractiveAuthorization,
    );
  }

  /// Record an active portal request.
  void addRequest(XdgPortalRequest request) {
    _requests[request.path] = request;
  }

  /// Record an active portal session.
  void addSession(XdgPortalSession session) {
    _sessions[session.path] = session;
  }
}
