import 'dart:async';

import 'package:dbus/dbus.dart';

import '../xdg_desktop_portal_client.dart';
import '../xdg_portal_request.dart';
import '../xdg_portal_session.dart';
import 'xdg_location.dart';

/// A location session.
class XdgLocationSession extends XdgPortalSession {
  /// The client that is connected to this portal.
  XdgDesktopPortalClient portalClient;

  final StreamController<XdgLocation> controller;

  XdgLocationSession(this.portalClient, DBusObjectPath path, this.controller)
      : super(portalClient, path);

  /// Start this session.
  Future<XdgPortalRequest> start({String parentWindow = ''}) async {
    var options = <String, DBusValue>{};
    var result = await portalClient.callMethod(
      'org.freedesktop.portal.Location',
      'Start',
      [path, DBusString(parentWindow), DBusDict.stringVariant(options)],
      replySignature: DBusSignature('o'),
    );
    var handle = result.returnValues[0].asObjectPath();
    var request = XdgPortalRequest(portalClient, handle);
    portalClient.addRequest(request);
    return request;
  }

  @override
  Future<void> handleClosed() async {
    await controller.close();
  }
}
