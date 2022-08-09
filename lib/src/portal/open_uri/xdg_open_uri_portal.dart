import 'package:dbus/dbus.dart';
import '../xdg_desktop_portal_client.dart';
import '../xdg_portal_request.dart';

/// Portal to open URIs.
class XdgOpenUriPortal {
  /// The client that is connected to this portal.
  XdgDesktopPortalClient client;

  XdgOpenUriPortal(this.client);

  /// Ask to open a URI.
  Future<void> openUri(
    String uri, {
    String parentWindow = '',
    bool? writable,
    bool? ask,
    String? activationToken,
  }) async {
    var options = <String, DBusValue>{};
    options['handle_token'] = DBusString(client.generateToken());
    if (writable != null) {
      options['writable'] = DBusBoolean(writable);
    }
    if (ask != null) {
      options['ask'] = DBusBoolean(ask);
    }
    if (activationToken != null) {
      options['activation_token'] = DBusString(activationToken);
    }
    var result = await client.callMethod(
      'org.freedesktop.portal.OpenURI',
      'OpenURI',
      [
        DBusString(parentWindow),
        DBusString(uri),
        DBusDict.stringVariant(options),
      ],
      replySignature: DBusSignature('o'),
    );
    var request = XdgPortalRequest(
      client,
      result.returnValues[0].asObjectPath(),
    );
    client.addRequest(request);
    await request.checkSuccess();
  }

  // FIXME: OpenFile

  // FIXME: OpenDirectory
}
