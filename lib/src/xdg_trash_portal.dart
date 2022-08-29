import 'package:dbus/dbus.dart';

/// Portal for trashing files.
class XdgTrashPortal {
  final DBusRemoteObject _object;

  XdgTrashPortal(this._object);

  /// Get the version of this portal.
  Future<int> getVersion() => _object
      .getProperty('org.freedesktop.portal.Trash', 'version',
          signature: DBusSignature('u'))
      .then((v) => v.asUint32());
}
