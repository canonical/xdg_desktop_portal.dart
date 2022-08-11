import 'dart:async';

import 'package:dbus/dbus.dart';

/// A session opened on a portal.
class XdgPortalSession {
  /// Stream for the session.
  Stream<void> get stream => _controller.stream;

  final DBusRemoteObject _portalObject;
  StreamSubscription? _sessionClosedSubscription;
  final Future<DBusObjectPath> Function() _send;
  late final StreamController<void> _controller;

  /// The object representing this session.
  DBusRemoteObject? get object => _object;
  DBusRemoteObject? _object;

  Future<bool> get created => _createdCompleter.future;
  final _createdCompleter = Completer<bool>();

  XdgPortalSession(this._portalObject, this._send) {
    _controller =
        StreamController<void>(onListen: _onListen, onCancel: _onCancel);
  }

  /// Send the request.
  Future<void> _onListen() async {
    var sessionClosed = DBusSignalStream(_portalObject.client,
        interface: 'org.freedesktop.portal.Session',
        name: 'Closed',
        signature: DBusSignature(''));
    _sessionClosedSubscription = sessionClosed.listen((signal) {
      if (signal.path == _object?.path) {
        _controller.close();
      }
    });
    var path = await _send();
    _object = DBusRemoteObject(_portalObject.client,
        name: _portalObject.name, path: path);
    _createdCompleter.complete(true);
  }

  Future<void> _onCancel() async {
    await _sessionClosedSubscription?.cancel();

    // Ensure that we have started the stream
    await _createdCompleter.future;

    try {
      await _object?.callMethod('org.freedesktop.portal.Session', 'Close', [],
          replySignature: DBusSignature(''));
    } on DBusMethodResponseException {
      // Ignore errors, as the request may have completed before the close request was received.
    }
  }
}
