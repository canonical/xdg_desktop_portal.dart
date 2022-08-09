import 'package:dbus/dbus.dart';

import '../xdg_desktop_portal_client.dart';

/// Portal to access system settings.
class XdgSettingsPortal {
  /// The client that is connected to this portal.
  XdgDesktopPortalClient client;

  XdgSettingsPortal(this.client);

  /// Read a single value.
  Future<DBusValue> read(String namespace, String key) async {
    var result = await client.callMethod(
      'org.freedesktop.portal.Settings',
      'Read',
      [DBusString(namespace), DBusString(key)],
      replySignature: DBusSignature('v'),
    );
    return result.returnValues[0].asVariant();
  }

  /// Read all the the settings in the given [namespaces].
  /// Globbing is allowed on trailing sections, e.g. 'com.example.*'.
  Future<Map<String, Map<String, DBusValue>>> readAll(
      Iterable<String> namespaces) async {
    var result = await client.callMethod(
      'org.freedesktop.portal.Settings',
      'ReadAll',
      [DBusArray.string(namespaces)],
      replySignature: DBusSignature(
        'a{sa{sv}}',
      ),
    );
    return result.returnValues[0].asDict().map(
        (key, value) => MapEntry(key.asString(), value.asStringVariantDict()));
  }
}
