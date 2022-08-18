import 'package:dbus/dbus.dart';

import 'xdg_portal_request.dart';

enum XdgRemoteDesktopDeviceType { none, keyboard, pointer, touchscreen }

enum XdgRemoteDesktopButtonState { released, pressed }

/// Remote desktop portal.
class XdgRemoteDesktopPortal {
  final DBusRemoteObject _object;
  final String Function() _generateToken;
  DBusObjectPath? _sessionPath;

  XdgRemoteDesktopPortal(this._object, this._generateToken);

  /// Get the version of this portal.
  Future<int> getVersion() => _object
      .getProperty('org.freedesktop.portal.Secret', 'version',
          signature: DBusSignature('u'))
      .then((v) => v.asUint32());

  /// Create a remote desktop portal.
  Future<Set<XdgRemoteDesktopDeviceType>> createSession(
      {String parentWindow = '',
      Set<XdgRemoteDesktopDeviceType>? deviceTypes}) async {
    /// Call CreateSession.
    var requestCreateSession = XdgPortalRequest(_object, () async {
      var options = <String, DBusValue>{};
      options['handle_token'] = DBusString(_generateToken());
      options['session_handle_token'] = DBusString(_generateToken());
      var createResult = await _object.callMethod(
          'org.freedesktop.portal.RemoteDesktop',
          'CreateSession',
          [DBusDict.stringVariant(options)],
          replySignature: DBusSignature('o'));
      return createResult.returnValues[0].asObjectPath();
    });

    final resultCreateSession = await requestCreateSession.stream.first;
    _sessionPath =
        DBusObjectPath(resultCreateSession['session_handle']?.asString() ?? '');

    var requestSelectDevices = XdgPortalRequest(_object, () async {
      var options = <String, DBusValue>{};
      options['handle_token'] = DBusString(_generateToken());
      if (deviceTypes != null) {
        int bitmask = 0;
        for (final type in deviceTypes) {
          if (type == XdgRemoteDesktopDeviceType.keyboard) bitmask |= 1;
          if (type == XdgRemoteDesktopDeviceType.pointer) bitmask |= 2;
          if (type == XdgRemoteDesktopDeviceType.touchscreen) bitmask |= 4;
        }
        options['types'] = DBusUint32(bitmask);
      }

      /// Call SelectDevices.
      var result = await _object.callMethod(
        'org.freedesktop.portal.RemoteDesktop',
        'SelectDevices',
        [
          _sessionPath!,
          DBusDict.stringVariant(options),
        ],
        replySignature: DBusSignature('o'),
      );
      return result.returnValues[0].asObjectPath();
    });
    await requestSelectDevices.stream.first;

    /// Call Start.
    var requestStart = XdgPortalRequest(_object, () async {
      var options = <String, DBusValue>{};
      options['handle_token'] = DBusString(_generateToken());
      var result = await _object.callMethod(
        'org.freedesktop.portal.RemoteDesktop',
        'Start',
        [
          _sessionPath!,
          DBusString(parentWindow),
          DBusDict.stringVariant(options),
        ],
        replySignature: DBusSignature('o'),
      );
      return result.returnValues[0].asObjectPath();
    });
    final resultStart = await requestStart.stream.first;
    final deviceTypesValue = resultStart['devices']?.asUint32() ?? 0;
    final devices = <XdgRemoteDesktopDeviceType>{};
    if (deviceTypesValue & 1 != 0) {
      devices.add(XdgRemoteDesktopDeviceType.keyboard);
    }
    if (deviceTypesValue & 2 != 0) {
      devices.add(XdgRemoteDesktopDeviceType.pointer);
    }
    if (deviceTypesValue & 4 != 0) {
      devices.add(XdgRemoteDesktopDeviceType.touchscreen);
    }
    return devices;
  }

  /// Notify about a new relative pointer motion event.
  /// The (dx, dy) vector represents the new pointer position in the streams logical coordinate space.
  Future<void> notifyPointerMotion(
      {required double dx, required double dy}) async {
    var options = <String, DBusValue>{};
    await _object.callMethod(
      'org.freedesktop.portal.RemoteDesktop',
      'NotifyPointerMotion',
      [
        _sessionPath!,
        DBusDict.stringVariant(options),
        DBusDouble(dx),
        DBusDouble(dy),
      ],
      replySignature: DBusSignature(''),
    );
  }

  /// Notify about a new absolute pointer motion event.
  /// The (x, y) position represents the new pointer position in the streams logical coordinate space.
  Future<void> notifyPointerMotionAbsolute(
      {required int nodeId, required double x, required double y}) async {
    var options = <String, DBusValue>{};
    await _object.callMethod(
      'org.freedesktop.portal.RemoteDesktop',
      'NotifyPointerMotionAbsolute',
      [
        _sessionPath!,
        DBusDict.stringVariant(options),
        DBusUint32(nodeId),
        DBusDouble(x),
        DBusDouble(y),
      ],
      replySignature: DBusSignature(''),
    );
  }

  /// Notify about a new relative pointer motion event.
  /// The (dx, dy) vector represents the new pointer position in the streams logical coordinate space.
  Future<void> notifyPointerButton(
      {required int button, required XdgRemoteDesktopButtonState state}) async {
    //TODO: May only be called if POINTER access was provided after starting the session.
    var options = <String, DBusValue>{};
    await _object.callMethod(
      'org.freedesktop.portal.RemoteDesktop',
      'NotifyPointerButton',
      [
        _sessionPath!,
        DBusDict.stringVariant(options),
        DBusInt32(button),
        DBusUint32(state.index),
      ],
      replySignature: DBusSignature(''),
    );
  }
}
