import 'package:dbus/dbus.dart';

import 'xdg_portal_request.dart';

/// Portal to send email.
class XdgEmailPortal {
  final DBusRemoteObject _object;
  final String Function() _generateToken;

  XdgEmailPortal(this._object, this._generateToken);

  /// Get the version of this portal.
  Future<int> getVersion() => _object
      .getProperty('org.freedesktop.portal.Email', 'version',
          signature: DBusSignature('u'))
      .then((v) => v.asUint32());

  /// Present a window to compose an email.
  Future<void> composeEmail(
      {String parentWindow = '',
      String? address,
      Iterable<String> addresses = const [],
      Iterable<String> cc = const [],
      Iterable<String> bcc = const [],
      String? subject,
      String? body}) async {
    var request = XdgPortalRequest(_object, () async {
      var options = <String, DBusValue>{};
      options['handle_token'] = DBusString(_generateToken());
      if (address != null) {
        options['address'] = DBusString(address);
      }
      if (addresses.isNotEmpty) {
        options['addresses'] = DBusArray.string(addresses);
      }
      if (cc.isNotEmpty) {
        options['cc'] = DBusArray.string(cc);
      }
      if (bcc.isNotEmpty) {
        options['bcc'] = DBusArray.string(bcc);
      }
      if (subject != null) {
        options['subject'] = DBusString(subject);
      }
      if (body != null) {
        options['body'] = DBusString(body);
      }
      var result = await _object.callMethod(
          'org.freedesktop.portal.Email',
          'ComposeEmail',
          [DBusString(parentWindow), DBusDict.stringVariant(options)],
          replySignature: DBusSignature('o'));
      return result.returnValues[0].asObjectPath();
    });
    await request.stream.first;
  }
}
