import 'package:dbus/dbus.dart';

import 'xdg_desktop_portal_client.dart';

/// A session opened on a portal.
abstract class XdgPortalSession extends DBusRemoteObject {
  XdgPortalSession(XdgDesktopPortalClient client, DBusObjectPath path)
      : super(client.bus, name: client.name, path: path);

  /// Close the session.
  Future<void> close() async {
    await callMethod(
      'org.freedesktop.portal.Session',
      'Close',
      [],
      replySignature: DBusSignature(''),
    );
  }

  /// Called when the session is closed by the portal
  Future<void> handleClosed();
}
