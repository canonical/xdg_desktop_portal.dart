import 'dart:io';

import 'package:dbus/dbus.dart';

/// Exception thrown when fail to trash a file.
class XdgTrashFileException implements Exception {
  /// Result code received from portal.
  final int result;

  XdgTrashFileException(this.result);

  @override
  String toString() => 'Failed to trash file, portal returned $result';
}

/// Portal for trashing files.
class XdgTrashPortal {
  final DBusRemoteObject _object;

  XdgTrashPortal(this._object);

  /// Get the version of this portal.
  Future<int> getVersion() => _object
      .getProperty('org.freedesktop.portal.Trash', 'version',
          signature: DBusSignature('u'))
      .then((v) => v.asUint32());

  /// Send a file to the trashcan.
  Future<void> trashFile(File file) async {
    var f = await file.open();
    var result = await _object.callMethod(
        'org.freedesktop.portal.Trash',
        'TrashFile',
        [
          DBusUnixFd(ResourceHandle.fromFile(f)),
        ],
        replySignature: DBusSignature('u'));
    await f.close();

    var r = result.returnValues[0].asUint32();
    if (r != 1) {
      throw XdgTrashFileException(r);
    }
  }
}
