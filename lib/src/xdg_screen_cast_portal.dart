import 'dart:async';

import 'package:dbus/dbus.dart';

/// Portal to perform screen casts.
class XdgScreenCastPortal {
  final DBusRemoteObject _object;

  XdgScreenCastPortal(this._object);

  /// Get the version of this portal.
  Future<int> getVersion() => _object
      .getProperty('org.freedesktop.portal.ScreenCast', 'version',
          signature: DBusSignature('u'))
      .then((v) => v.asUint32());
}
