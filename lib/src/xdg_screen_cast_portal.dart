import 'dart:async';
import 'dart:io';

import 'package:dbus/dbus.dart';

import 'xdg_portal_request.dart';

/// Source types of screen cast.
enum ScreenCastAvailableSourceType { monitor, window, virtual }

/// Cursor modes of screen cast.
enum ScreenCastAvailableCursorMode { hidden, embedded, metadata }

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

class ScreenCastStream {
  final int nodeId;
  final String id;
  final List<int> position;
  final List<int> size;
  final ScreenCastAvailableSourceType sourceType;

  ScreenCastStream({
    required this.nodeId,
    required this.id,
    required this.position,
    required this.size,
    required this.sourceType,
  });
  @override
  int get hashCode => Object.hash(
      nodeId, id, Object.hashAll(position), Object.hashAll(size), sourceType);

  @override
  bool operator ==(other) =>
      other is ScreenCastStream &&
      other.nodeId == nodeId &&
      other.id == id &&
      other.position == position &&
      other.size == size &&
      other.sourceType == sourceType;

  @override
  String toString() =>
      '$runtimeType(node ID: $nodeId, id: $id, position: $position, size: $size, sourceType: $sourceType})';
}

/// Screen cast portal.
class XdgScreenCastPortal {
  final DBusRemoteObject _object;
  final String Function() _generateToken;

  DBusObjectPath? _sessionPath;

  XdgScreenCastPortal(this._object, this._generateToken);

  /// Get the version of this portal.
  Future<int> getVersion() => _object
      .getProperty('org.freedesktop.portal.ScreenCast', 'version',
          signature: DBusSignature('u'))
      .then((v) => v.asUint32());

  /// Get the available screen cast source types.
  Future<Set<ScreenCastAvailableSourceType>> getAvailableSourceTypes() =>
      _object
          .getProperty(
              'org.freedesktop.portal.ScreenCast', 'AvailableSourceTypes',
              signature: DBusSignature('u'))
          .then((v) {
        final value = v.asUint32();
        final types = <ScreenCastAvailableSourceType>{};
        if (value & 1 != 0) types.add(ScreenCastAvailableSourceType.monitor);
        if (value & 2 != 0) types.add(ScreenCastAvailableSourceType.window);
        if (value & 4 != 0) types.add(ScreenCastAvailableSourceType.virtual);
        return types;
      });

  /// Get the available screen cast cursor modes.
  Future<Set<ScreenCastAvailableCursorMode>> getAvailableCursorModes() =>
      _object
          .getProperty(
              'org.freedesktop.portal.ScreenCast', 'AvailableCursorModes',
              signature: DBusSignature('u'))
          .then((v) {
        final value = v.asUint32();
        final types = <ScreenCastAvailableCursorMode>{};
        if (value & 1 != 0) types.add(ScreenCastAvailableCursorMode.hidden);
        if (value & 2 != 0) types.add(ScreenCastAvailableCursorMode.embedded);
        if (value & 4 != 0) types.add(ScreenCastAvailableCursorMode.metadata);
        return types;
      });

  /// Create a location session that returns a stream of location updates from the portal.
  /// When the session is no longer required close the stream.
  Future<void> createSession() async {
    var request = XdgPortalRequest(_object, () async {
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

    final result = await request.stream.first;
    final sessionHandle = result['session_handle']?.asString() ?? '';
    _sessionPath = DBusObjectPath(sessionHandle);
  }

  /// Configure what the screen cast session should record.
  /// This method must be called before starting the session.
  Future<void> selectSources({
    Set<ScreenCastAvailableSourceType>? sourceTypes,
    bool? multiple,
    Set<ScreenCastAvailableCursorMode>? cursorModes,
    String? restoreToken,
    ScreenCastSessionPersistMode? persistMode,
  }) async {
    var request = XdgPortalRequest(_object, () async {
      var options = <String, DBusValue>{};
      options['handle_token'] = DBusString(_generateToken());
      if (sourceTypes != null) {
        int bitmask = 0;
        for (final type in sourceTypes) {
          if (type == ScreenCastAvailableSourceType.monitor) bitmask |= 1;
          if (type == ScreenCastAvailableSourceType.window) bitmask |= 2;
          if (type == ScreenCastAvailableSourceType.virtual) bitmask |= 4;
        }
        options['types'] = DBusUint32(bitmask);
      }
      if (multiple != null) {
        options['multiple'] = DBusBoolean(multiple);
      }
      if (cursorModes != null) {
        int bitmask = 0;
        for (final mode in cursorModes) {
          if (mode == ScreenCastAvailableCursorMode.hidden) bitmask |= 1;
          if (mode == ScreenCastAvailableCursorMode.embedded) bitmask |= 2;
          if (mode == ScreenCastAvailableCursorMode.metadata) bitmask |= 4;
        }
        options['cursor_mode'] = DBusUint32(bitmask);
      }
      if (restoreToken != null) {
        options['restore_token'] = DBusString(restoreToken);
      }
      if (persistMode != null) {
        options['persist_mode'] = DBusUint32(persistMode.index);
      }
      var result = await _object.callMethod(
        'org.freedesktop.portal.ScreenCast',
        'SelectSources',
        [
          _sessionPath!,
          DBusDict.stringVariant(options),
        ],
        replySignature: DBusSignature('o'),
      );
      return result.returnValues[0].asObjectPath();
    });
    await request.stream.first;
  }

  Future<List<ScreenCastStream>> start({String parentWindow = ''}) async {
    var request = XdgPortalRequest(_object, () async {
      var options = <String, DBusValue>{};
      options['handle_token'] = DBusString(_generateToken());
      var result = await _object.callMethod(
        'org.freedesktop.portal.ScreenCast',
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
    final resultResult = await request.stream.first;
    final streams = resultResult['streams']!.asArray();
    return streams.map((stream) {
      final params = stream.asStruct();
      final nodeId = params[0].asUint32();
      final properties = params[1].asStringVariantDict();
      final id = properties['id']!.asString();
      final sourceTypeValue = properties['source_type']!.asUint32();
      ScreenCastAvailableSourceType sourceType =
          ScreenCastAvailableSourceType.monitor;
      if (sourceTypeValue & 1 != 0) {
        sourceType = ScreenCastAvailableSourceType.monitor;
      } else if (sourceTypeValue & 2 != 0) {
        sourceType = ScreenCastAvailableSourceType.window;
      } else if (sourceTypeValue & 4 != 0) {
        sourceType = ScreenCastAvailableSourceType.virtual;
      }
      final positionArray = properties['position']!.asStruct();
      final position = [positionArray[0].asInt32(), positionArray[1].asInt32()];
      final sizeArray = properties['size']!.asStruct();
      final size = [sizeArray[0].asInt32(), sizeArray[1].asInt32()];
      return ScreenCastStream(
        nodeId: nodeId,
        id: id,
        sourceType: sourceType,
        position: position,
        size: size,
      );
    }).toList();
  }

  /// Open a file descriptor to the PipeWire remote where the camera nodes are available.
  Future<ResourceHandle> openPipeWireRemote() async {
    var options = <String, DBusValue>{};
    var result = await _object.callMethod(
      'org.freedesktop.portal.ScreenCast',
      'OpenPipeWireRemote',
      [
        _sessionPath!,
        DBusDict.stringVariant(options),
      ],
      replySignature: DBusSignature('h'),
    );
    return result.returnValues[0].asUnixFd();
  }
}
