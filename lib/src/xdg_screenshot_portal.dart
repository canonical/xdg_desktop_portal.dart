import 'package:dbus/dbus.dart';

import 'xdg_portal_request.dart';

/// Portal for taking screenshots.
class XdgScreenshotPortal {
  final DBusRemoteObject _object;
  final String Function() _generateToken;

  XdgScreenshotPortal(this._object, this._generateToken);

  /// Get the version of this portal.
  Future<int> getVersion() => _object
      .getProperty('org.freedesktop.portal.Screenshot', 'version',
          signature: DBusSignature('u'))
      .then((v) => v.asUint32());

  /// Take a screenshot.
  Future<Uri?> screenshot({
    String parentWindow = '',
    bool? modal,
    bool? interactive,
  }) async {
    var request = XdgPortalRequest(
      _object,
      () async {
        var options = <String, DBusValue>{};
        options['handle_token'] = DBusString(_generateToken());
        if (modal != null) {
          options['modal'] = DBusBoolean(modal);
        }
        if (interactive != null) {
          options['interactive'] = DBusBoolean(interactive);
        }
        var result = await _object.callMethod(
            'org.freedesktop.portal.Screenshot',
            'Screenshot',
            [DBusString(parentWindow), DBusDict.stringVariant(options)],
            replySignature: DBusSignature('o'));
        return result.returnValues[0].asObjectPath();
      },
    );
    return request.stream.single.then((result) {
      final uri = result['uri']?.asString();
      if (uri == null) {
        return null;
      }
      return Uri.tryParse(uri);
    });
  }

  /// Obtains the color of a single pixel.
  Future<List<double>?> pickColor({String parentWindow = ''}) {
    var request = XdgPortalRequest(
      _object,
      () async {
        var options = <String, DBusValue>{};
        options['handle_token'] = DBusString(_generateToken());
        var result = await _object.callMethod(
            'org.freedesktop.portal.Screenshot',
            'PickColor',
            [DBusString(parentWindow), DBusDict.stringVariant(options)],
            replySignature: DBusSignature('o'));
        return result.returnValues[0].asObjectPath();
      },
    );
    return request.stream.single.then((result) {
      final color = result['color']?.asStruct();
      if (color == null) {
        return null;
      }
      return color.map((v) => v.asDouble()).toList();
    });
  }
}
