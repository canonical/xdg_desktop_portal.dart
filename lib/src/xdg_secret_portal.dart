import 'dart:io';

import 'package:dbus/dbus.dart';

import 'xdg_portal_request.dart';

/// Portal for retrieving application secret.
class XdgSecretPortal {
  final DBusRemoteObject _object;
  final String Function() _generateToken;

  XdgSecretPortal(this._object, this._generateToken);

  /// Retrieves a master secret for a sandboxed application.
  Future<void> retrieveSecret(RandomAccessFile file,
      {String token = ''}) async {
    var request = XdgPortalRequest(_object, () async {
      var options = <String, DBusValue>{};
      options['handle_token'] = DBusString(_generateToken());
      options['token'] = DBusString(token);
      var result = await _object.callMethod(
          'org.freedesktop.portal.Secret',
          'RetrieveSecret',
          [
            DBusUnixFd(ResourceHandle.fromFile(file)),
            DBusDict.stringVariant(options),
          ],
          replySignature: DBusSignature('o'));
      return result.returnValues[0].asObjectPath();
    });
    await request.stream.first;
  }
}
