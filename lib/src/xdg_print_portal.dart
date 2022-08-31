import 'package:dbus/dbus.dart';

/// Portal for printing.
class XdgPrintPortal {
  final DBusRemoteObject _object;

  XdgPrintPortal(this._object);

  /// Get the version of this portal.
  Future<int> getVersion() => _object
      .getProperty('org.freedesktop.portal.Print', 'version',
          signature: DBusSignature('u'))
      .then((v) => v.asUint32());
}
