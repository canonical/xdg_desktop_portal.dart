import 'package:dbus/dbus.dart';

import 'xdg_portal_request.dart';

enum XdgDeviceType { microphone, speakers, camera }

/// Portal for device access.
class XdgDevicePortal {
  final DBusRemoteObject _object;
  final String Function() _generateToken;

  XdgDevicePortal(this._object, this._generateToken);

  /// Get the version of this portal.
  Future<int> getVersion() => _object
      .getProperty('org.freedesktop.portal.Device', 'version',
          signature: DBusSignature('u'))
      .then((v) => v.asUint32());

  /// Request to gain access to a device.
  Future<void> accessDevice({
    required int pid,
    required List<XdgDeviceType> devices,
  }) async {
    var request = XdgPortalRequest(_object, () async {
      var options = <String, DBusValue>{};
      options['handle_token'] = DBusString(_generateToken());
      var result = await _object.callMethod(
        'org.freedesktop.portal.Device',
        'AccessDevice',
        [
          DBusUint32(pid),
          DBusArray.string(devices.map((device) => device.name)),
          DBusDict.stringVariant(options),
        ],
        replySignature: DBusSignature('o'),
      );
      return result.returnValues[0].asObjectPath();
    });
    await request.stream.first;
  }
}
