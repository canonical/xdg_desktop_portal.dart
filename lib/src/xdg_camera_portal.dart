import 'dart:io';

import 'package:dbus/dbus.dart';

import 'xdg_portal_request.dart';

/// Camera portal.
class XdgCameraPortal {
  final DBusRemoteObject _object;
  final String Function() _generateToken;

  XdgCameraPortal(this._object, this._generateToken);

  /// Check to access camera.
  Future<void> accessCamera() async {
    var request = XdgPortalRequest(_object, () async {
      var options = <String, DBusValue>{};
      options['handle_token'] = DBusString(_generateToken());
      var result = await _object.callMethod(
        'org.freedesktop.portal.Camera',
        'AccessCamera',
        [DBusDict.stringVariant(options)],
        replySignature: DBusSignature('o'),
      );
      return result.returnValues[0].asObjectPath();
    });
    await request.stream.first;
  }

  /// Open a file descriptor to the PipeWire remote where the camera nodes are available.
  Future<ResourceHandle> openPipeWireRemote() async {
    var options = <String, DBusValue>{};
    var result = await _object.callMethod(
      'org.freedesktop.portal.Camera',
      'OpenPipeWireRemote',
      [DBusDict.stringVariant(options)],
      replySignature: DBusSignature('h'),
    );
    return result.returnValues[0].asUnixFd();
  }
}
