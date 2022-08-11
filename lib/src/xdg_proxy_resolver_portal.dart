import 'package:dbus/dbus.dart';

/// Portal to use system proxy.
class XdgProxyResolverPortal {
  final DBusRemoteObject _object;

  XdgProxyResolverPortal(this._object);

  /// Looks up which proxy to use to connect to [uri].
  /// 'direct://' is returned when no proxy is needed.
  Future<List<String>> lookup(String uri) async {
    var result = await _object.callMethod(
        'org.freedesktop.portal.ProxyResolver', 'Lookup', [DBusString(uri)],
        replySignature: DBusSignature('as'));
    return result.returnValues[0].asStringArray().toList();
  }
}
