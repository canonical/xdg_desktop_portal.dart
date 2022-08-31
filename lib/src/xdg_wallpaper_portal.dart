import 'package:dbus/dbus.dart';

/// Portal for setting the desktop wallpaper.
class XdgWallpaperPortal {
  final DBusRemoteObject _object;

  XdgWallpaperPortal(this._object);

  /// Get the version of this portal.
  Future<int> getVersion() => _object
      .getProperty('org.freedesktop.portal.Wallpaper', 'version',
          signature: DBusSignature('u'))
      .then((v) => v.asUint32());
}
