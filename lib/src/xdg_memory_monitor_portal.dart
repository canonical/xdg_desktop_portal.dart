import 'package:dbus/dbus.dart';

/// Portal to monitor memory.
class XdgMemoryMonitorPortal {
  final DBusRemoteObject _object;

  XdgMemoryMonitorPortal(this._object);

  /// Get the version of this portal.
  Future<int> getVersion() => _object
      .getProperty('org.freedesktop.portal.MemoryMonitor', 'version',
          signature: DBusSignature('u'))
      .then((v) => v.asUint32());
}
