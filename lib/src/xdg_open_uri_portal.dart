import 'package:dbus/dbus.dart';

import 'xdg_portal_request.dart';

/// Portal to open URIs.
class XdgOpenUriPortal {
  final DBusRemoteObject _object;
  final String Function() _generateToken;

  XdgOpenUriPortal(this._object, this._generateToken);

  /// Get the version of this portal.
  Future<int> getVersion() => _object
      .getProperty('org.freedesktop.portal.OpenURI', 'version',
          signature: DBusSignature('u'))
      .then((v) => v.asUint32());

  /// Ask to open a URI.
  Future<void> openUri(String uri,
      {String parentWindow = '',
      bool? writable,
      bool? ask,
      String? activationToken}) async {
    var request = XdgPortalRequest(_object, () async {
      var options = <String, DBusValue>{};
      options['handle_token'] = DBusString(_generateToken());
      if (writable != null) {
        options['writable'] = DBusBoolean(writable);
      }
      if (ask != null) {
        options['ask'] = DBusBoolean(ask);
      }
      if (activationToken != null) {
        options['activation_token'] = DBusString(activationToken);
      }
      var result = await _object.callMethod(
          'org.freedesktop.portal.OpenURI',
          'OpenURI',
          [
            DBusString(parentWindow),
            DBusString(uri),
            DBusDict.stringVariant(options)
          ],
          replySignature: DBusSignature('o'));
      return result.returnValues[0].asObjectPath();
    });
    await request.stream.first;
  }

  // FIXME: OpenFile

  // FIXME: OpenDirectory
}
