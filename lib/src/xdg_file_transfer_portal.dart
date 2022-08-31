import 'dart:async';

import 'package:dbus/dbus.dart';

/// Portal to transfer files between applications.
class XdgFileTransferPortal {
  final DBusRemoteObject _object;

  XdgFileTransferPortal(this._object);

  /// Get the version of this portal.
  Future<int> getVersion() => _object
      .getProperty('org.freedesktop.portal.FileTransfer', 'version',
          signature: DBusSignature('u'))
      .then((v) => v.asUint32());
}
