import 'package:dbus/dbus.dart';

/// Portal for power profile monitoring.
class XdgPowerProfileMonitorPortal {
  final DBusRemoteObject _object;

  XdgPowerProfileMonitorPortal(this._object);

  /// Get the version of this portal.
  Future<int> getVersion() => _object
      .getProperty('org.freedesktop.portal.PowerProfileMonitor', 'version',
          signature: DBusSignature('u'))
      .then((v) => v.asUint32());
}
