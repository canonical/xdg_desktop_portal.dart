import 'dart:io';
import 'dart:typed_data';

import 'package:dbus/dbus.dart';

import 'xdg_portal_request.dart';

/// Portal for retrieving application secret.
class XdgSecretPortal {
  final DBusRemoteObject _object;
  final String Function() _generateToken;

  XdgSecretPortal(this._object, this._generateToken);

  /// Get the version of this portal.
  Future<int> getVersion() => _object
      .getProperty('org.freedesktop.portal.Secret', 'version',
          signature: DBusSignature('u'))
      .then((v) => v.asUint32());

  /// Retrieves a master secret for a sandboxed application.
  Future<Uint8List> retrieveSecret({String? token}) async {
    var dir = Directory.systemTemp.createTempSync();
    var file = await File('${dir.path}/secret').create();
    var accessFile = await file.open(mode: FileMode.write);

    var request = XdgPortalRequest(_object, () async {
      var options = <String, DBusValue>{};
      options['handle_token'] = DBusString(_generateToken());
      if (token != null) {
        options['token'] = DBusString(token);
      }
      var result = await _object.callMethod(
          'org.freedesktop.portal.Secret',
          'RetrieveSecret',
          [
            DBusUnixFd(ResourceHandle.fromFile(accessFile)),
            DBusDict.stringVariant(options),
          ],
          replySignature: DBusSignature('o'));
      return result.returnValues[0].asObjectPath();
    });
    await request.stream.first;

    await accessFile.setPosition(0);
    final length = await accessFile.length();
    final secret = await accessFile.read(length);
    await accessFile.close();

    dir.deleteSync(recursive: true);
    return secret;
  }
}
