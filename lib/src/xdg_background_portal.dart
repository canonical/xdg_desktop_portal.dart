import 'package:dbus/dbus.dart';

import 'xdg_portal_request.dart';

/// Result of a request asking for an allowed to run in the background.
class XdgBackgroundPortalRequestResult {
  /// TRUE if the application is allowed to run in the background.
  final bool background;

  /// TRUE if the application is will be autostarted.
  final bool autostart;

  XdgBackgroundPortalRequestResult(
      {required this.background, required this.autostart});

  @override
  int get hashCode => Object.hash(background, autostart);

  @override
  bool operator ==(other) =>
      other is XdgBackgroundPortalRequestResult &&
      other.background == background &&
      other.autostart == autostart;

  @override
  String toString() =>
      '$runtimeType(background: $background, autostart: $autostart)';
}

/// Portal for requesting autostart and background activity.
class XdgBackgroundPortal {
  final DBusRemoteObject _object;
  final String Function() _generateToken;

  XdgBackgroundPortal(this._object, this._generateToken);

  /// Ask to request that the application is allowed to run in the background.
  Stream<XdgBackgroundPortalRequestResult> requestBackground({
    String parentWindow = '',
    String reason = '',
    bool autostart = false,
    required List<String> commandLine,
    bool dBusActivatable = false,
  }) {
    var request = XdgPortalRequest(
      _object,
      () async {
        var options = <String, DBusValue>{};
        options['handle_token'] = DBusString(_generateToken());
        options['reason'] = DBusString(reason);
        options['autostart'] = DBusBoolean(autostart);
        options['commandline'] = DBusArray.string(commandLine);
        options['dbus-activatable'] = DBusBoolean(dBusActivatable);
        var result = await _object.callMethod(
            'org.freedesktop.portal.Background',
            'RequestBackground',
            [DBusString(parentWindow), DBusDict.stringVariant(options)],
            replySignature: DBusSignature('o'));
        return result.returnValues[0].asObjectPath();
      },
    );
    return request.stream.map(
      (result) {
        return XdgBackgroundPortalRequestResult(
          background: result['background']?.asBoolean() ?? false,
          autostart: result['autostart']?.asBoolean() ?? false,
        );
      },
    );
  }
}
