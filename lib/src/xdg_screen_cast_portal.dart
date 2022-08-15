import 'dart:async';
import 'dart:io';

import 'package:dbus/dbus.dart';

import 'xdg_portal_request.dart';
import 'xdg_portal_session.dart';

/// Source types of screen cast.
enum ScreenCastAvailableSourceTypes { monitor, window, virtual }

/// Cursor modes of screen cast.
enum ScreenCastAvailableCursorModes { hidden, embedded, metadata }

/// Persist mode of screen cast session.
/// Remote desktop screen cast sessions cannot persist.
/// The only allowed persist_mode for remote desktop sessions is no.
enum ScreenCastSessionPersistMode {
  /// Do not persist.
  no,

  ///Permissions persist as long as the application is running.
  running,

  /// Permissions persist until explicitly revoked.
  untilRevoked
}

/// Screen cast portal.
class XdgScreenCastPortal {
  final DBusRemoteObject _object;
  final String Function() _generateToken;

  XdgPortalSession? _session;
  StreamSubscription? _sessionSubscription;

  XdgScreenCastPortal(this._object, this._generateToken);

  /// Get the version of this portal.
  Future<int> getVersion() => _object
      .getProperty('org.freedesktop.portal.ScreenCast', 'version',
          signature: DBusSignature('u'))
      .then((v) => v.asUint32());

  /// Get the available screen cast source types.
  Future<Set<ScreenCastAvailableSourceTypes>> getAvailableSourceTypes() =>
      _object
          .getProperty(
              'org.freedesktop.portal.ScreenCast', 'AvailableSourceTypes',
              signature: DBusSignature('u'))
          .then((v) {
        final value = v.asUint32();
        final types = <ScreenCastAvailableSourceTypes>{};
        if (value & 1 != 0) types.add(ScreenCastAvailableSourceTypes.monitor);
        if (value & 2 != 0) types.add(ScreenCastAvailableSourceTypes.window);
        if (value & 4 != 0) types.add(ScreenCastAvailableSourceTypes.virtual);
        return types;
      });

  /// Get the available screen cast cursor modes.
  Future<Set<ScreenCastAvailableCursorModes>> getAvailableCursorModes() =>
      _object
          .getProperty(
              'org.freedesktop.portal.ScreenCast', 'AvailableCursorModes',
              signature: DBusSignature('u'))
          .then((v) {
        final value = v.asUint32();
        final types = <ScreenCastAvailableCursorModes>{};
        if (value & 1 != 0) types.add(ScreenCastAvailableCursorModes.hidden);
        if (value & 2 != 0) types.add(ScreenCastAvailableCursorModes.embedded);
        if (value & 4 != 0) types.add(ScreenCastAvailableCursorModes.metadata);
        return types;
      });

  /// Create a location session that returns a stream of location updates from the portal.
  /// When the session is no longer required close the stream.
  Future<void> createSession() async {
    _session = XdgPortalSession(_object, () async {
      var options = <String, DBusValue>{};
      options['handle_token'] = DBusString(_generateToken());
      options['session_handle_token'] = DBusString(_generateToken());
      var createResult = await _object.callMethod(
          'org.freedesktop.portal.ScreenCast',
          'CreateSession',
          [DBusDict.stringVariant(options)],
          replySignature: DBusSignature('o'));
      return createResult.returnValues[0].asObjectPath();
    });
    _sessionSubscription = _session!.stream.listen((_) {
      print('onData');
    }, onDone: () async {
      print('onDone');
    });
    bool value = await _session!.created;
    print(value);
    //final value2 = _session!.stream.first;
    //print(value2);
  }

  /// Configure what the screen cast session should record.
  /// This method must be called before starting the session.
  Future<void> selectSources({
    Set<ScreenCastAvailableSourceTypes>? sourceTypes,
    bool? multiple,
    Set<ScreenCastAvailableCursorModes>? cursorModes,
    String? restoreToken,
    ScreenCastSessionPersistMode? persistMode,
  }) async {
    var request = XdgPortalRequest(_object, () async {
      var options = <String, DBusValue>{};
      options['handle_token'] = DBusString(_generateToken());
      if (sourceTypes != null) {
        int bitmask = 0;
        for (final type in sourceTypes) {
          if (type == ScreenCastAvailableSourceTypes.monitor) bitmask |= 1;
          if (type == ScreenCastAvailableSourceTypes.window) bitmask |= 2;
          if (type == ScreenCastAvailableSourceTypes.virtual) bitmask |= 4;
        }
        options['types'] = DBusUint32(bitmask);
      }
      if (multiple != null) {
        options['multiple'] = DBusBoolean(multiple);
      }
      if (cursorModes != null) {
        int bitmask = 0;
        for (final mode in cursorModes) {
          if (mode == ScreenCastAvailableCursorModes.hidden) bitmask |= 1;
          if (mode == ScreenCastAvailableCursorModes.embedded) bitmask |= 2;
          if (mode == ScreenCastAvailableCursorModes.metadata) bitmask |= 4;
        }
        options['cursor_mode'] = DBusUint32(bitmask);
      }
      if (restoreToken != null) {
        options['restore_token'] = DBusString(restoreToken);
      }
      if (persistMode != null) {
        options['persist_mode'] = DBusUint32(persistMode.index);
      }
      print('session: ${_session!.object!.path}');
      print('options: $options');
      var result = await _object.callMethod(
        'org.freedesktop.portal.ScreenCast',
        'SelectSources',
        [
          _session!.object!.path,
          DBusDict.stringVariant(options),
        ],
        replySignature: DBusSignature('o'),
      );
      return result.returnValues[0].asObjectPath();
    });
    final result = await request.stream.first;
    print(result);
  }

  Future<void> start({String parentWindow = ''}) async {
    var request = XdgPortalRequest(_object, () async {
      var options = <String, DBusValue>{};
      options['handle_token'] = DBusString(_generateToken());

      var result = await _object.callMethod(
        'org.freedesktop.portal.ScreenCast',
        'Start',
        [
          _session!.object!.path,
          DBusString(parentWindow),
          DBusDict.stringVariant(options),
        ],
        replySignature: DBusSignature('o'),
      );
      return result.returnValues[0].asObjectPath();
    });
    await request.stream.first;
  }

  /// Open a file descriptor to the PipeWire remote where the camera nodes are available.
  Future<ResourceHandle> openPipeWireRemote() async {
    var options = <String, DBusValue>{};
    var result = await _object.callMethod(
      'org.freedesktop.portal.ScreenCast',
      'OpenPipeWireRemote',
      [
        _session!.object!.path,
        DBusDict.stringVariant(options),
      ],
      replySignature: DBusSignature('h'),
    );
    return result.returnValues[0].asUnixFd();
  }

  Future<void> close() async {
    await _sessionSubscription?.cancel();
  }
}
