import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
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

  /// Permissions persist as long as the application is running.
  running,

  /// Permissions persist until explicitly revoked.
  untilRevoked
}

/// PipeWire stream properties.
class ScreenCastStream {
  /// The PipeWire node ID.
  final int nodeId;

  /// Opaque identifier.
  final String id;

  final int x;
  final int y;
  final int width;
  final int height;

  /// The type of the content which is being screen casted.
  final ScreenCastAvailableSourceType sourceType;

  ScreenCastStream({
    required this.nodeId,
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.sourceType,
  });
  @override
  int get hashCode => Object.hash(nodeId, id, x, y, width, height, sourceType);

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;

    return other is ScreenCastStream &&
        other.nodeId == nodeId &&
        other.id == id &&
        other.x == x &&
        other.y == y &&
        other.width == width &&
        other.height == height &&
        other.sourceType == sourceType;
  }

  @override
  String toString() =>
      '$runtimeType(node ID: $nodeId, id: $id, position: ($x, $y), size: ($width, $height), sourceType: $sourceType})';
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

  /// Create a screen cast session.
  Future<List<ScreenCastStream>> createSession({
    String parentWindow = '',
    Set<ScreenCastAvailableSourceType>? sourceTypes,
    bool? multiple,
    Set<ScreenCastAvailableCursorMode>? cursorModes,
    String? restoreToken,
    ScreenCastSessionPersistMode? persistMode,
  }) async {
    var requestCreateSession = XdgPortalRequest(_object, () async {
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

    final resultCreateSession = await requestCreateSession.stream.first;
    _sessionPath =
        DBusObjectPath(resultCreateSession['session_handle']?.asString() ?? '');

    var requestSelectSources = XdgPortalRequest(_object, () async {
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
    await requestSelectSources.stream.first;

    var requestStart = XdgPortalRequest(_object, () async {
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
    final resultStart = await requestStart.stream.first;
    final streams = resultStart['streams']!.asArray();
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
      final sizeArray = properties['size']!.asStruct();
      return ScreenCastStream(
        nodeId: nodeId,
        id: id,
        sourceType: sourceType,
        x: positionArray[0].asInt32(),
        y: positionArray[1].asInt32(),
        width: sizeArray[0].asInt32(),
        height: sizeArray[1].asInt32(),
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
