import 'dart:async';

import 'package:dbus/dbus.dart';

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
/// This class is used by portal implementations, it should not be required for normal portal API usage.
class XdgPortalRequest {
  /// Stream containing the single result returned from the portal.
  Stream<Map<String, DBusValue>> get stream => _controller.stream;

  final Future<DBusRemoteObject> Function(XdgPortalRequest) _send;
  late final StreamController<Map<String, DBusValue>> _controller;
  final _listenCompleter = Completer();
  late final DBusRemoteObject _object;
  var _haveResponse = false;

  XdgPortalRequest(this._send) {
    _controller = StreamController<Map<String, DBusValue>>(
        onListen: _onListen, onCancel: _onCancel);
  }

  Future<void> _onListen() async {
    _object = await _send(this);
    _listenCompleter.complete();
  }

  Future<void> _onCancel() async {
    // Ensure that we have started the stream
    await _listenCompleter.future;

    // If got a response, then the request object has already been removed.
    if (!_haveResponse) {
      try {
        await _object.callMethod('org.freedesktop.portal.Request', 'Close', [],
            replySignature: DBusSignature(''));
      } on DBusMethodResponseException {
        // Ignore errors, as the request may have completed before the close request was received.
      }
    }
  }

  /// Process the response received for this request.
  void handleResponse(int response, Map<String, DBusValue> result) {
    _haveResponse = true;
    switch (response) {
      case 0:
        _controller.add(result);
        return;
      case 1:
        _controller.addError(XdgPortalRequestCancelledException());
        break;
      case 2:
      default:
        _controller.addError(XdgPortalRequestFailedException());
        break;
    }
    _controller.close();
  }
}
