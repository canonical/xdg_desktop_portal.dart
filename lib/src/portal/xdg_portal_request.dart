import 'dart:async';

import 'package:dbus/dbus.dart';

import 'xdg_desktop_portal_client.dart';
import 'xdg_portal_response.dart';

/// Exception thrown when a portal request fails due to it being cancelled.
class XdgPortalRequestCancelledException implements Exception {
  @override
  String toString() => 'Request was cancelled';
}

/// Exception thrown when a portal request fails.
class XdgPortalRequestFailedException implements Exception {
  @override
  String toString() => 'Request failed';
}

/// A request sent to a portal.
class XdgPortalRequest extends DBusRemoteObject {
  /// The result of this request.
  Future<XdgPortalResponse> get response => _response.future;
  final _response = Completer<XdgPortalResponse>();

  XdgPortalRequest(XdgDesktopPortalClient client, DBusObjectPath path)
      : super(client.bus, name: client.name, path: path);

  /// Waits for a success response to be received or throws an exception.
  Future<void> checkSuccess() async {
    switch (await response) {
      case XdgPortalResponse.success:
        return;
      case XdgPortalResponse.cancelled:
        throw XdgPortalRequestCancelledException();
      case XdgPortalResponse.other:
      default:
        throw XdgPortalRequestFailedException();
    }
  }

  /// Ends the user interaction with this request.
  Future<void> close() async {
    await callMethod(
      'org.freedesktop.portal.Request',
      'Close',
      [],
      replySignature: DBusSignature(''),
    );
  }

  void handleResponse(
      XdgPortalResponse response, Map<String, DBusValue> result) {
    _response.complete(response);
  }
}
