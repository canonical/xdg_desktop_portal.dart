import 'package:dbus/dbus.dart';

/// Portal to use remote desktop.
class XdgRemoteDesktopPortal {
  final DBusRemoteObject _object;

  XdgRemoteDesktopPortal(this._object);

  /// Get the version of this portal.
  Future<int> getVersion() => _object
      .getProperty('org.freedesktop.portal.RemoteDesktop', 'version',
          signature: DBusSignature('u'))
      .then((v) => v.asUint32());
}
