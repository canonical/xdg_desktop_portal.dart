import 'package:dbus/dbus.dart';

import 'xdg_portal_request.dart';

/// Result of a request asking for an allowed to run in the background.
class XdgBackgroundPortalRequestResult {
  /// true if the application is allowed to run in the background.
  final bool background;

  /// true if the application is will be autostarted.
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

  /// Get the version of this portal.
  Future<int> getVersion() => _object
      .getProperty('org.freedesktop.portal.Background', 'version',
          signature: DBusSignature('u'))
      .then((v) => v.asUint32());

  /// Ask to request that the application is allowed to run in the background.
  Stream<XdgBackgroundPortalRequestResult> requestBackground({
    String parentWindow = '',
    String? reason,
    bool? autostart,
    required List<String>? commandLine,
    bool? dBusActivatable,
  }) {
    var request = XdgPortalRequest(
      _object,
      () async {
        var options = <String, DBusValue>{};
        options['handle_token'] = DBusString(_generateToken());
        if (reason != null) {
          options['reason'] = DBusString(reason);
        }
        if (autostart != null) {
          options['autostart'] = DBusBoolean(autostart);
        }
        if (commandLine != null) {
          options['commandline'] = DBusArray.string(commandLine);
        }
        if (dBusActivatable != null) {
          options['dbus-activatable'] = DBusBoolean(dBusActivatable);
        }
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
