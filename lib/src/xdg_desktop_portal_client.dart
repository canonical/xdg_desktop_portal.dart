import 'dart:async';
import 'package:dbus/dbus.dart';

/// A client that connects to the portals.
class XdgDesktopPortalClient {
  /// The bus this client is connected to.
  final DBusClient _bus;
  final bool _closeBus;

  late final DBusRemoteObject _object;

  /// Creates a new portal client. If [bus] is provided connect to the given D-Bus server.
  XdgDesktopPortalClient({DBusClient? bus})
      : _bus = bus ?? DBusClient.session(),
        _closeBus = bus == null {
    _object = DBusRemoteObject(_bus,
        name: 'org.freedesktop.portal.Desktop',
        path: DBusObjectPath('/org/freedesktop/desktop/portal'));
  }

  Future<DBusValue> settingsRead(String namespace, String key) async {
    var result = await _object.callMethod('org.freedesktop.portal.Settings',
        'Read', [DBusString(namespace), DBusString(key)],
        replySignature: DBusSignature('v'));
    return (result.returnValues[0] as DBusVariant).value;
  }

  /// Terminates all active connections. If a client remains unclosed, the Dart process may not terminate.
  Future<void> close() async {
    if (_closeBus) {
      await _bus.close();
    }
  }
}
