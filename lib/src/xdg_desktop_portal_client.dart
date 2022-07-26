import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
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
class _XdgPortalRequest {
  /// The client that is the request is from.
  XdgDesktopPortalClient client;

  /// Stream containing the single result returned from the portal.
  Stream<Map<String, DBusValue>> get stream => _controller.stream;

  final Future<DBusObjectPath> Function() _send;
  late final StreamController<Map<String, DBusValue>> _controller;
  final _listenCompleter = Completer();
  late final DBusRemoteObject _object;
  var _haveResponse = false;

  _XdgPortalRequest(this.client, this._send) {
    _controller = StreamController<Map<String, DBusValue>>(
        onListen: _onListen, onCancel: _onCancel);
  }

  /// Send the request.
  Future<void> _onListen() async {
    var path = await _send();
    _object =
        DBusRemoteObject(client._bus, name: client._object.name, path: path);
    client._addRequest(path, this);
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

  void _handleResponse(
      _XdgPortalResponse response, Map<String, DBusValue> result) {
    _haveResponse = true;
    switch (response) {
      case _XdgPortalResponse.success:
        _controller.add(result);
        return;
      case _XdgPortalResponse.cancelled:
        _controller.addError(XdgPortalRequestCancelledException());
        break;
      case _XdgPortalResponse.other:
      default:
        _controller.addError(XdgPortalRequestFailedException());
        break;
    }
    _controller.close();
  }
}

/// Response from a portal request.
enum _XdgPortalResponse { success, cancelled, other }

/// A session opened on a portal.
abstract class _XdgPortalSession extends DBusRemoteObject {
  _XdgPortalSession(XdgDesktopPortalClient client, DBusObjectPath path)
      : super(client._bus, name: client._object.name, path: path);

  /// Close the session.
  Future<void> close() async {
    await callMethod('org.freedesktop.portal.Session', 'Close', [],
        replySignature: DBusSignature(''));
  }

  /// Called when the session is closed by the portal
  Future<void> _handleClosed();
}

/// Portal to send email.
class XdgEmailPortal {
  /// The client that is connected to this portal.
  XdgDesktopPortalClient client;

  XdgEmailPortal(this.client);

  /// Present a window to compose an email.
  Future<void> composeEmail(
      {String parentWindow = '',
      String? address,
      Iterable<String> addresses = const [],
      Iterable<String> cc = const [],
      Iterable<String> bcc = const [],
      String? subject,
      String? body}) async {
    var request = _XdgPortalRequest(client, () async {
      var options = <String, DBusValue>{};
      options['handle_token'] = DBusString(client._generateToken());
      if (address != null) {
        options['address'] = DBusString(address);
      }
      if (addresses.isNotEmpty) {
        options['addresses'] = DBusArray.string(addresses);
      }
      if (cc.isNotEmpty) {
        options['cc'] = DBusArray.string(cc);
      }
      if (bcc.isNotEmpty) {
        options['bcc'] = DBusArray.string(bcc);
      }
      if (subject != null) {
        options['subject'] = DBusString(subject);
      }
      if (body != null) {
        options['body'] = DBusString(body);
      }
      var result = await client._object.callMethod(
          'org.freedesktop.portal.Email',
          'ComposeEmail',
          [DBusString(parentWindow), DBusDict.stringVariant(options)],
          replySignature: DBusSignature('o'));
      return result.returnValues[0].asObjectPath();
    });
    await request.stream.first;
  }
}

/// A pattern used to match files.
abstract class XdgFileChooserFilterPattern {
  int get _id;
  String get _pattern;

  XdgFileChooserFilterPattern();
}

/// A pattern used to match files using a glob string.
class XdgFileChooserGlobPattern extends XdgFileChooserFilterPattern {
  /// A glob patterns, e.g. '*.png'
  final String pattern;

  @override
  int get _id => 0;

  @override
  String get _pattern => pattern;

  XdgFileChooserGlobPattern(this.pattern);
}

/// A pattern used to match files using a MIME type.
class XdgFileChooserMimeTypePattern extends XdgFileChooserFilterPattern {
  /// A MIME type, e.g. 'image/png'
  final String mimeType;

  @override
  int get _id => 1;

  @override
  String get _pattern => mimeType;

  XdgFileChooserMimeTypePattern(this.mimeType);
}

/// A file filter in use in a file chooser.
class XdgFileChooserFilter {
  /// The name of this filter.
  final String name;

  /// Patterns to match files against.
  final List<XdgFileChooserFilterPattern> patterns;

  XdgFileChooserFilter(
      this.name, Iterable<XdgFileChooserFilterPattern> patterns)
      : patterns = patterns.toList();
}

XdgFileChooserFilter? _decodeFilter(DBusValue? value) {
  if (value == null || value.signature != DBusSignature('(sa(us))')) {
    return null;
  }

  var nameAndPatterns = value.asStruct();
  var name = nameAndPatterns[0].asString();
  var patterns = nameAndPatterns[1]
      .asArray()
      .map((v) {
        var idAndPattern = v.asStruct();
        var id = idAndPattern[0].asUint32();
        var pattern = idAndPattern[1].asString();
        switch (id) {
          case 0:
            return XdgFileChooserGlobPattern(pattern);
          case 1:
            return XdgFileChooserMimeTypePattern(pattern);
          default:
            return null;
        }
      })
      .where((p) => p != null)
      .cast<XdgFileChooserFilterPattern>();

  return XdgFileChooserFilter(name, patterns);
}

DBusValue _encodeFilter(XdgFileChooserFilter filter) {
  return DBusStruct([
    DBusString(filter.name),
    DBusArray(
        DBusSignature('(us)'),
        filter.patterns.map((pattern) => DBusStruct(
            [DBusUint32(pattern._id), DBusString(pattern._pattern)])))
  ]);
}

DBusValue _encodeFilters(Iterable<XdgFileChooserFilter> filters) {
  return DBusArray(
      DBusSignature('(sa(us))'), filters.map((f) => _encodeFilter(f)));
}

/// A choice to give the user in a file chooser dialog.
/// Normally implemented as a combo box.
class XdgFileChooserChoice {
  /// Unique ID for this choice.
  final String id;

  /// User-visible label for this choice.
  final String label;

  /// User visible value labels keyed by ID.
  final Map<String, String> values;

  /// ID of the initiially selected value in [values].
  final String initialSelection;

  XdgFileChooserChoice(
      {required this.id,
      required this.label,
      this.values = const {},
      this.initialSelection = ''});

  DBusValue _encode() {
    return DBusStruct([
      DBusString(id),
      DBusString(label),
      DBusArray(
          DBusSignature('(ss)'),
          values.entries.map(
              (e) => DBusStruct([DBusString(e.key), DBusString(e.value)]))),
      DBusString(initialSelection)
    ]);
  }
}

DBusValue _encodeChoices(Iterable<XdgFileChooserChoice> choices) {
  return DBusArray(
      DBusSignature('(ssa(ss)s)'), choices.map((c) => c._encode()));
}

Map<String, String> _decodeChoicesResult(DBusValue? value) {
  if (value == null || value.signature != DBusSignature('a(ss)')) {
    return {};
  }

  var result = <String, String>{};
  for (var v in value.asArray()) {
    var ids = v.asStruct();
    var choiceId = ids[0].asString();
    var valueId = ids[1].asString();
    result[choiceId] = valueId;
  }

  return result;
}

/// Result of a request for access to files.
class XdgFileChooserPortalOpenFileResult {
  /// The URIs selected in the file chooser.
  var uris = <String>[];

  /// Result of the choices taken in the chooser.
  Map<String, String> choices;

  /// Selected filter that was used in the chooser.
  XdgFileChooserFilter? currentFilter;

  XdgFileChooserPortalOpenFileResult(
      {required this.uris,
      this.choices = const {},
      required this.currentFilter});
}

/// Result of a request asking for a location to save a file.
class XdgFileChooserPortalSaveFileResult {
  /// The URIs selected in the file chooser.
  var uris = <String>[];

  /// Result of the choices taken in the chooser.
  Map<String, String> choices;

  /// Selected filter that was used in the chooser.
  XdgFileChooserFilter? currentFilter;

  XdgFileChooserPortalSaveFileResult(
      {required this.uris,
      this.choices = const {},
      required this.currentFilter});
}

/// Result of a request asking for a folder as a location to save one or more files.
class XdgFileChooserPortalSaveFilesResult {
  /// The URIs selected in the file chooser.
  var uris = <String>[];

  /// Result of the choices taken in the chooser.
  Map<String, String> choices;

  XdgFileChooserPortalSaveFilesResult(
      {required this.uris, this.choices = const {}});
}

/// Portal to request access to files.
class XdgFileChooserPortal {
  /// The client that is connected to this portal.
  XdgDesktopPortalClient client;

  XdgFileChooserPortal(this.client);

  /// Ask to open one or more files.
  Stream<XdgFileChooserPortalOpenFileResult> openFile(
      {required String title,
      String parentWindow = '',
      String? acceptLabel,
      bool? modal,
      bool? multiple,
      bool? directory,
      Iterable<XdgFileChooserFilter> filters = const [],
      XdgFileChooserFilter? currentFilter,
      Iterable<XdgFileChooserChoice> choices = const []}) {
    var request = _XdgPortalRequest(client, () async {
      var options = <String, DBusValue>{};
      options['handle_token'] = DBusString(client._generateToken());
      if (acceptLabel != null) {
        options['accept_label'] = DBusString(acceptLabel);
      }
      if (modal != null) {
        options['modal'] = DBusBoolean(modal);
      }
      if (multiple != null) {
        options['multiple'] = DBusBoolean(multiple);
      }
      if (directory != null) {
        options['directory'] = DBusBoolean(directory);
      }
      if (filters.isNotEmpty) {
        options['filters'] = _encodeFilters(filters);
      }
      if (currentFilter != null) {
        options['current_filter'] = _encodeFilter(currentFilter);
      }
      if (choices.isNotEmpty) {
        options['choices'] = _encodeChoices(choices);
      }
      var result = await client._object.callMethod(
          'org.freedesktop.portal.FileChooser',
          'OpenFile',
          [
            DBusString(parentWindow),
            DBusString(title),
            DBusDict.stringVariant(options)
          ],
          replySignature: DBusSignature('o'));
      return result.returnValues[0].asObjectPath();
    });
    return request.stream.map((result) {
      var urisValue = result['uris'];
      var uris = urisValue?.signature == DBusSignature('as')
          ? urisValue!.asStringArray().toList()
          : <String>[];
      var choicesResult = _decodeChoicesResult(result['choices']);
      var selectedFilter = _decodeFilter(result['current_filter']);

      return XdgFileChooserPortalOpenFileResult(
          uris: uris, choices: choicesResult, currentFilter: selectedFilter);
    });
  }

  /// Ask for a location to save a file.
  Stream<XdgFileChooserPortalSaveFileResult> saveFile(
      {required String title,
      String parentWindow = '',
      String? acceptLabel,
      bool? modal,
      Iterable<XdgFileChooserFilter> filters = const [],
      XdgFileChooserFilter? currentFilter,
      Iterable<XdgFileChooserChoice> choices = const [],
      String? currentName,
      Uint8List? currentFolder,
      Uint8List? currentFile}) {
    var request = _XdgPortalRequest(client, () async {
      var options = <String, DBusValue>{};
      options['handle_token'] = DBusString(client._generateToken());
      if (acceptLabel != null) {
        options['accept_label'] = DBusString(acceptLabel);
      }
      if (modal != null) {
        options['modal'] = DBusBoolean(modal);
      }
      if (filters.isNotEmpty) {
        options['filters'] = _encodeFilters(filters);
      }
      if (currentFilter != null) {
        options['current_filter'] = _encodeFilter(currentFilter);
      }
      if (choices.isNotEmpty) {
        options['choices'] = _encodeChoices(choices);
      }
      if (currentName != null) {
        options['current_name'] = DBusString(currentName);
      }
      if (currentFolder != null) {
        options['current_folder'] = DBusArray.byte(currentFolder);
      }
      if (currentFile != null) {
        options['current_file'] = DBusArray.byte(currentFile);
      }
      var result = await client._object.callMethod(
          'org.freedesktop.portal.FileChooser',
          'SaveFile',
          [
            DBusString(parentWindow),
            DBusString(title),
            DBusDict.stringVariant(options)
          ],
          replySignature: DBusSignature('o'));
      return result.returnValues[0].asObjectPath();
    });
    return request.stream.map((result) {
      var urisValue = result['uris'];
      var uris = urisValue?.signature == DBusSignature('as')
          ? urisValue!.asStringArray().toList()
          : <String>[];
      var choicesResult = _decodeChoicesResult(result['choices']);
      var selectedFilter = _decodeFilter(result['current_filter']);

      return XdgFileChooserPortalSaveFileResult(
          uris: uris, choices: choicesResult, currentFilter: selectedFilter);
    });
  }

  /// Ask for a folder as a location to save one or more files.
  Stream<XdgFileChooserPortalSaveFilesResult> saveFiles(
      {required String title,
      String parentWindow = '',
      String? acceptLabel,
      bool? modal,
      Iterable<XdgFileChooserChoice> choices = const [],
      Uint8List? currentFolder,
      Iterable<Uint8List> files = const []}) {
    var request = _XdgPortalRequest(client, () async {
      var options = <String, DBusValue>{};
      options['handle_token'] = DBusString(client._generateToken());
      if (acceptLabel != null) {
        options['accept_label'] = DBusString(acceptLabel);
      }
      if (modal != null) {
        options['modal'] = DBusBoolean(modal);
      }
      if (choices.isNotEmpty) {
        options['choices'] = _encodeChoices(choices);
      }
      if (currentFolder != null) {
        options['current_folder'] = DBusArray.byte(currentFolder);
      }
      if (files.isNotEmpty) {
        options['files'] =
            DBusArray(DBusSignature('ay'), files.map((f) => DBusArray.byte(f)));
      }
      var result = await client._object.callMethod(
          'org.freedesktop.portal.FileChooser',
          'SaveFiles',
          [
            DBusString(parentWindow),
            DBusString(title),
            DBusDict.stringVariant(options)
          ],
          replySignature: DBusSignature('o'));
      return result.returnValues[0].asObjectPath();
    });
    return request.stream.map((result) {
      var urisValue = result['uris'];
      var uris = urisValue?.signature == DBusSignature('as')
          ? urisValue!.asStringArray().toList()
          : <String>[];
      var choicesResult = _decodeChoicesResult(result['choices']);

      return XdgFileChooserPortalSaveFilesResult(
          uris: uris, choices: choicesResult);
    });
  }
}

/// Network connectivity states.
enum XdgNetworkConnectivity { local, limited, portal, full }

class XdgNetworkStatus {
  /// true if the network is available.
  bool available;

  /// true if the network is metered.
  bool metered;

  /// The network connectivity state.
  XdgNetworkConnectivity connectivity;

  XdgNetworkStatus(
      {required this.available,
      required this.metered,
      required this.connectivity});

  @override
  int get hashCode => Object.hash(available, metered, connectivity);

  @override
  bool operator ==(other) =>
      other is XdgNetworkStatus &&
      other.available == available &&
      other.metered == metered &&
      other.connectivity == connectivity;

  @override
  String toString() =>
      '$runtimeType(available: $available, metered: $metered, connectivity: $connectivity)';
}

class _NetworkStatusStreamController {
  final XdgNetworkMonitorPortal portal;
  late final StreamController<XdgNetworkStatus> controller;

  Stream<XdgNetworkStatus> get stream => controller.stream;

  _NetworkStatusStreamController(this.portal) {
    controller = StreamController<XdgNetworkStatus>(
        onListen: _onListen, onCancel: _onCancel);
  }

  Future<void> _onListen() async {
    portal._activeStatusControllers.add(this);
    await portal._updateChangedSubscription();
    controller.add(await portal._getLastStatus());
  }

  Future<void> _onCancel() async {
    portal._activeStatusControllers.remove(this);
    await portal._updateChangedSubscription();
  }
}

/// Portal to monitor networking.
class XdgNetworkMonitorPortal {
  /// The client that is connected to this portal.
  XdgDesktopPortalClient client;

  /// Streams listening to status updates.
  final _activeStatusControllers = <_NetworkStatusStreamController>[];

  /// Signal sent by portal when the status changes.
  late final DBusRemoteObjectSignalStream _changed;
  StreamSubscription? _changedSubscription;

  // Last received status update, or null if not subscribed to status updates.
  XdgNetworkStatus? _lastStatus;

  XdgNetworkMonitorPortal(this.client) {
    _changed = DBusRemoteObjectSignalStream(
        object: client._object,
        interface: 'org.freedesktop.portal.NetworkMonitor',
        name: 'changed',
        signature: DBusSignature(''));
  }

  /// Get network status updates.
  Stream<XdgNetworkStatus> get status {
    var controller = _NetworkStatusStreamController(this);
    return controller.stream;
  }

  /// Returns true if the given [hostname]:[port] is believed to be reachable.
  Future<bool> canReach(String hostname, int port) async {
    var result = await client._object.callMethod(
        'org.freedesktop.portal.NetworkMonitor',
        'CanReach',
        [DBusString(hostname), DBusUint32(port)],
        replySignature: DBusSignature('b'));
    return result.returnValues[0].asBoolean();
  }

  /// Subscribe or unsubscribe to the changed signal.
  Future<void> _updateChangedSubscription() async {
    if (_activeStatusControllers.isNotEmpty) {
      _changedSubscription ??=
          _changedSubscription = _changed.listen((signal) async {
        await _updateStatus();
        for (var c in _activeStatusControllers) {
          c.controller.add(_lastStatus!);
        }
      });
    } else {
      var s = _changedSubscription;
      _changedSubscription = null;
      _lastStatus = null;
      await s?.cancel();
    }
  }

  /// Gets the status of the network, using the cached version if subscribed to updates.
  Future<XdgNetworkStatus> _getLastStatus() async {
    return _lastStatus ?? await _updateStatus();
  }

  /// Get the current status of the network from the portal.
  Future<XdgNetworkStatus> _updateStatus() async {
    var result = await client._object.callMethod(
        'org.freedesktop.portal.NetworkMonitor', 'GetStatus', [],
        replySignature: DBusSignature('a{sv}'));
    var options = result.returnValues[0].asStringVariantDict();
    var available = false;
    var availableValue = options['available'];
    if (availableValue != null && availableValue is DBusBoolean) {
      available = availableValue.asBoolean();
    }
    var metered = false;
    var meteredValue = options['metered'];
    if (meteredValue != null && meteredValue is DBusBoolean) {
      metered = meteredValue.asBoolean();
    }
    var connectivity = XdgNetworkConnectivity.full;
    var connectivityValue = options['connectivity'];
    if (connectivityValue != null && connectivityValue is DBusUint32) {
      connectivity = {
            0: XdgNetworkConnectivity.local,
            1: XdgNetworkConnectivity.limited,
            2: XdgNetworkConnectivity.portal,
            3: XdgNetworkConnectivity.full
          }[connectivityValue.asUint32()] ??
          XdgNetworkConnectivity.full;
    }
    _lastStatus = XdgNetworkStatus(
        available: available, metered: metered, connectivity: connectivity);
    return _lastStatus!;
  }

  Future<void> _close() async {
    await _changedSubscription?.cancel();
  }
}

/// Priorities for notifications.
enum XdgNotificationPriority { low, normal, high, urgent }

/// An icon to be shown in a notification.
abstract class XdgNotificationIcon {}

/// An icon stored in the file system.
class XdgNotificationIconFile extends XdgNotificationIcon {
  /// Path of this icon
  final String path;

  XdgNotificationIconFile(this.path);
}

/// An icon at a URI.
class XdgNotificationIconUri extends XdgNotificationIcon {
  /// Uri of this icon
  final String uri;

  XdgNotificationIconUri(this.uri);
}

/// A themed icon.
class XdgNotificationIconThemed extends XdgNotificationIcon {
  /// Theme names to lookup for this icon in order of priority.
  final List<String> names;

  XdgNotificationIconThemed(this.names);
}

/// An icon with image data.
class XdgNotificationIconData extends XdgNotificationIcon {
  /// Image data for this icon.
  final Uint8List data;

  XdgNotificationIconData(this.data);
}

/// A button to be shown in a notification.
class XdgNotificationButton {
  /// Label on this button.
  final String label;

  /// Action to perform with this button.
  final String action;

  XdgNotificationButton({required this.label, required this.action});
}

/// Portal to create notifications.
class XdgNotificationPortal {
  /// The client that is connected to this portal.
  XdgDesktopPortalClient client;

  XdgNotificationPortal(this.client);

  /// Send a notification.
  /// [id] can be used later to withdraw the notification with [removeNotification].
  /// If [id] is reused without withdrawing, the existing notification is replaced.
  Future<void> addNotification(String id,
      {String? title,
      String? body,
      XdgNotificationIcon? icon,
      XdgNotificationPriority? priority,
      String? defaultAction,
      List<XdgNotificationButton> buttons = const []}) async {
    var notification = <String, DBusValue>{};
    if (title != null) {
      notification['title'] = DBusString(title);
    }
    if (body != null) {
      notification['body'] = DBusString(body);
    }
    if (icon != null) {
      if (icon is XdgNotificationIconFile) {
        notification['icon'] = DBusStruct(
            [DBusString('file'), DBusVariant(DBusString(icon.path))]);
      } else if (icon is XdgNotificationIconUri) {
        notification['icon'] =
            DBusStruct([DBusString('file'), DBusVariant(DBusString(icon.uri))]);
      } else if (icon is XdgNotificationIconThemed) {
        notification['icon'] = DBusStruct(
            [DBusString('themed'), DBusVariant(DBusArray.string(icon.names))]);
      } else if (icon is XdgNotificationIconData) {
        notification['icon'] = DBusStruct(
            [DBusString('bytes'), DBusVariant(DBusArray.byte(icon.data))]);
      }
    }
    if (priority != null) {
      notification['priority'] = DBusString({
            XdgNotificationPriority.low: 'low',
            XdgNotificationPriority.normal: 'normal',
            XdgNotificationPriority.high: 'high',
            XdgNotificationPriority.urgent: 'urgent'
          }[priority] ??
          'normal');
    }
    if (defaultAction != null) {
      notification['default-action'] = DBusString(defaultAction);
    }
    if (buttons.isNotEmpty) {
      notification['buttons'] =
          DBusArray(DBusSignature('a{sv}'), buttons.map((button) {
        var values = {
          'label': DBusString(button.label),
          'action': DBusString(button.action)
        };
        return DBusDict.stringVariant(values);
      }));
    }
    await client._object.callMethod(
        'org.freedesktop.portal.Notification',
        'AddNotification',
        [DBusString(id), DBusDict.stringVariant(notification)],
        replySignature: DBusSignature(''));
  }

  /// Withdraw a notification created with [addNotification].
  Future<void> removeNotification(String id) async {
    await client._object.callMethod('org.freedesktop.portal.Notification',
        'RemoveNotification', [DBusString(id)],
        replySignature: DBusSignature(''));
  }
}

/// Requested accuracy of location information.
enum XdgLocationAccuracy { none, country, city, neighborhood, street, exact }

/// Location information.
class XdgLocation {
  // The latitude, in degrees.
  final double? latitude;

  // The longitude, in degrees.
  final double? longitude;

  // The altitude, in meters.
  final double? altitude;

  /// The accuracy, in meters.
  final double? accuracy;

  /// The speed, in meters per second.
  final double? speed;

  /// The heading, in degrees, going clockwise. North 0, East 90, South 180, West 270.
  final double? heading;

  /// Time time this location was recorded.
  final DateTime? timestamp;

  XdgLocation(
      {this.latitude,
      this.longitude,
      this.altitude,
      this.accuracy,
      this.speed,
      this.heading,
      this.timestamp});

  @override
  int get hashCode => Object.hash(
      latitude, longitude, altitude, accuracy, speed, heading, timestamp);

  @override
  bool operator ==(other) =>
      other is XdgLocation &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.altitude == altitude &&
      other.accuracy == accuracy &&
      other.speed == speed &&
      other.heading == heading &&
      other.timestamp == timestamp;

  @override
  String toString() =>
      '$runtimeType(latitude: $latitude, longitude: $longitude, altitude: $altitude, accuracy: $accuracy, speed: $speed, heading: $heading, timestamp: ${timestamp?.toUtc()})';
}

/// A location session.
class _XdgLocationSession extends _XdgPortalSession {
  /// The client that is connected to this portal.
  XdgDesktopPortalClient portalClient;

  final StreamController<XdgLocation> controller;

  _XdgLocationSession(this.portalClient, DBusObjectPath path, this.controller)
      : super(portalClient, path);

  /// Start this session.
  Future<_XdgPortalRequest> start({String parentWindow = ''}) async {
    var request = _XdgPortalRequest(portalClient, () async {
      var options = <String, DBusValue>{};
      var result = await portalClient._object.callMethod(
          'org.freedesktop.portal.Location',
          'Start',
          [path, DBusString(parentWindow), DBusDict.stringVariant(options)],
          replySignature: DBusSignature('o'));
      return result.returnValues[0].asObjectPath();
    });
    return request;
  }

  @override
  Future<void> _handleClosed() async {
    await controller.close();
  }
}

/// Provides a stream of locations using the portal APIs.
class _LocationStreamController {
  final XdgDesktopPortalClient client;
  late final StreamController<XdgLocation> controller;

  final int? distanceThreshold;
  final int? timeThreshold;
  final XdgLocationAccuracy? accuracy;
  final String parentWindow;

  _XdgLocationSession? session;

  /// Locations received from the portal.
  Stream<XdgLocation> get stream => controller.stream;

  _LocationStreamController(
      {required this.client,
      this.distanceThreshold,
      this.timeThreshold,
      this.accuracy,
      this.parentWindow = ''}) {
    controller =
        StreamController<XdgLocation>(onListen: _onListen, onCancel: _onCancel);
  }

  Future<void> _onListen() async {
    var options = <String, DBusValue>{};
    options['session_handle_token'] = DBusString(client._generateToken());
    if (distanceThreshold != null) {
      options['distance-threshold'] = DBusUint32(distanceThreshold!);
    }
    if (timeThreshold != null) {
      options['time-threshold'] = DBusUint32(timeThreshold!);
    }
    if (accuracy != null) {
      options['accuracy'] = DBusUint32({
            XdgLocationAccuracy.none: 0,
            XdgLocationAccuracy.country: 1,
            XdgLocationAccuracy.city: 2,
            XdgLocationAccuracy.neighborhood: 3,
            XdgLocationAccuracy.street: 4,
            XdgLocationAccuracy.exact: 5
          }[accuracy!] ??
          5);
    }
    var createResult = await client._object.callMethod(
        'org.freedesktop.portal.Location',
        'CreateSession',
        [DBusDict.stringVariant(options)],
        replySignature: DBusSignature('o'));
    session = _XdgLocationSession(
        client, createResult.returnValues[0].asObjectPath(), controller);
    client._addSession(session!);

    var startRequest = await session!.start(parentWindow: parentWindow);
    await startRequest.stream.first;
  }

  Future<void> _onCancel() async {
    await session?.close();
  }
}

/// Portal to get location information.
class XdgLocationPortal {
  /// The client that is connected to this portal.
  XdgDesktopPortalClient client;

  late final StreamSubscription _locationUpdatedSubscription;

  XdgLocationPortal(this.client) {
    var locationUpdated = DBusSignalStream(client._bus,
        interface: 'org.freedesktop.portal.Location',
        name: 'LocationUpdated',
        path: client._object.path,
        signature: DBusSignature('oa{sv}'));
    _locationUpdatedSubscription = locationUpdated.listen((signal) {
      var path = signal.values[0].asObjectPath();
      var session = client._sessions[path];
      if (session == null || session is! _XdgLocationSession) {
        return;
      }
      var location = signal.values[1].asStringVariantDict();
      double? getLocationValue(String name) {
        var value = location[name];
        if (value == null || value is! DBusDouble) {
          return null;
        }
        return value.asDouble();
      }

      DateTime? timestamp;
      var timestampValue = location['Timestamp'];
      if (timestampValue?.signature == DBusSignature('(tt)')) {
        var values = timestampValue!.asStruct();
        var s = values[0].asUint64();
        var us = values[1].asUint64();
        timestamp = DateTime.fromMicrosecondsSinceEpoch(s * 1000000 + us);
      }

      session.controller.add(XdgLocation(
          latitude: getLocationValue('Latitude'),
          longitude: getLocationValue('Longitude'),
          altitude: getLocationValue('Altitude'),
          accuracy: getLocationValue('Accuracy'),
          speed: getLocationValue('Speed'),
          heading: getLocationValue('Heading'),
          timestamp: timestamp));
    });
  }

  /// Create a location session that returns a stream of location updates from the portal.
  /// When the session is no longer required close the stream.
  Stream<XdgLocation> createSession(
      {int? distanceThreshold,
      int? timeThreshold,
      XdgLocationAccuracy? accuracy,
      String parentWindow = ''}) {
    var controller = _LocationStreamController(
        client: client,
        distanceThreshold: distanceThreshold,
        timeThreshold: timeThreshold,
        accuracy: accuracy,
        parentWindow: parentWindow);
    return controller.stream;
  }

  Future<void> _close() async {
    await _locationUpdatedSubscription.cancel();
  }
}

/// Portal to open URIs.
class XdgOpenUriPortal {
  /// The client that is connected to this portal.
  XdgDesktopPortalClient client;

  XdgOpenUriPortal(this.client);

  /// Ask to open a URI.
  Future<void> openUri(String uri,
      {String parentWindow = '',
      bool? writable,
      bool? ask,
      String? activationToken}) async {
    var request = _XdgPortalRequest(client, () async {
      var options = <String, DBusValue>{};
      options['handle_token'] = DBusString(client._generateToken());
      if (writable != null) {
        options['writable'] = DBusBoolean(writable);
      }
      if (ask != null) {
        options['ask'] = DBusBoolean(ask);
      }
      if (activationToken != null) {
        options['activation_token'] = DBusString(activationToken);
      }
      var result = await client._object.callMethod(
          'org.freedesktop.portal.OpenURI',
          'OpenURI',
          [
            DBusString(parentWindow),
            DBusString(uri),
            DBusDict.stringVariant(options)
          ],
          replySignature: DBusSignature('o'));
      return result.returnValues[0].asObjectPath();
    });
    await request.stream.first;
  }

  // FIXME: OpenFile

  // FIXME: OpenDirectory
}

/// Portal to use system proxy.
class XdgProxyResolverPortal {
  /// The client that is connected to this portal.
  XdgDesktopPortalClient client;

  XdgProxyResolverPortal(this.client);

  /// Looks up which proxy to use to connect to [uri].
  /// 'direct://' is returned when no proxy is needed.
  Future<List<String>> lookup(String uri) async {
    var result = await client._object.callMethod(
        'org.freedesktop.portal.ProxyResolver', 'Lookup', [DBusString(uri)],
        replySignature: DBusSignature('as'));
    return result.returnValues[0].asStringArray().toList();
  }
}

/// Portal to access system settings.
class XdgSettingsPortal {
  /// The client that is connected to this portal.
  XdgDesktopPortalClient client;

  XdgSettingsPortal(this.client);

  /// Read a single value.
  Future<DBusValue> read(String namespace, String key) async {
    var result = await client._object.callMethod(
        'org.freedesktop.portal.Settings',
        'Read',
        [DBusString(namespace), DBusString(key)],
        replySignature: DBusSignature('v'));
    return result.returnValues[0].asVariant();
  }

  /// Read all the the settings in the given [namespaces].
  /// Globbing is allowed on trailing sections, e.g. 'com.example.*'.
  Future<Map<String, Map<String, DBusValue>>> readAll(
      Iterable<String> namespaces) async {
    var result = await client._object.callMethod(
        'org.freedesktop.portal.Settings',
        'ReadAll',
        [DBusArray.string(namespaces)],
        replySignature: DBusSignature('a{sa{sv}}'));
    return result.returnValues[0].asDict().map(
        (key, value) => MapEntry(key.asString(), value.asStringVariantDict()));
  }
}

/// A client that connects to the portals.
class XdgDesktopPortalClient {
  /// The bus this client is connected to.
  final DBusClient _bus;
  final bool _closeBus;

  late final DBusRemoteObject _object;

  late final StreamSubscription _requestResponseSubscription;
  late final StreamSubscription _sessionClosedSubscription;

  final _requests = <DBusObjectPath, _XdgPortalRequest>{};
  final _sessions = <DBusObjectPath, _XdgPortalSession>{};

  /// Portal to send email.
  late final XdgEmailPortal email;

  /// Portal to request access to files.
  late final XdgFileChooserPortal fileChooser;

  /// Portal to get location information.
  late final XdgLocationPortal location;

  /// Portal to monitor networking.
  late final XdgNetworkMonitorPortal networkMonitor;

  /// Portal to create notifications.
  late final XdgNotificationPortal notification;

  /// Portal to open URIs.
  late final XdgOpenUriPortal openUri;

  /// Portal to use system proxy.
  late final XdgProxyResolverPortal proxyResolver;

  /// Portal to access system settings.
  late final XdgSettingsPortal settings;

  /// Keep track of used request/session tokens.
  final _usedTokens = <String>{};

  /// Creates a new portal client. If [bus] is provided connect to the given D-Bus server.
  XdgDesktopPortalClient({DBusClient? bus})
      : _bus = bus ?? DBusClient.session(),
        _closeBus = bus == null {
    _object = DBusRemoteObject(_bus,
        name: 'org.freedesktop.portal.Desktop',
        path: DBusObjectPath('/org/freedesktop/portal/desktop'));
    var requestResponse = DBusSignalStream(_bus,
        interface: 'org.freedesktop.portal.Request',
        name: 'Response',
        signature: DBusSignature('ua{sv}'));
    _requestResponseSubscription = requestResponse.listen((signal) {
      var request = _requests.remove(signal.path);
      if (request != null) {
        request._handleResponse(
            {
                  0: _XdgPortalResponse.success,
                  1: _XdgPortalResponse.cancelled,
                  2: _XdgPortalResponse.other
                }[signal.values[0].asUint32()] ??
                _XdgPortalResponse.other,
            signal.values[1].asStringVariantDict());
      }
    });
    var sessionClosed = DBusSignalStream(_bus,
        interface: 'org.freedesktop.portal.Session',
        name: 'Closed',
        signature: DBusSignature(''));
    _sessionClosedSubscription = sessionClosed.listen((signal) {
      var session = _sessions.remove(signal.path);
      if (session != null) {
        session._handleClosed();
      }
    });
    email = XdgEmailPortal(this);
    fileChooser = XdgFileChooserPortal(this);
    location = XdgLocationPortal(this);
    networkMonitor = XdgNetworkMonitorPortal(this);
    notification = XdgNotificationPortal(this);
    openUri = XdgOpenUriPortal(this);
    proxyResolver = XdgProxyResolverPortal(this);
    settings = XdgSettingsPortal(this);
  }

  /// Terminates all active connections. If a client remains unclosed, the Dart process may not terminate.
  Future<void> close() async {
    await _requestResponseSubscription.cancel();
    await _sessionClosedSubscription.cancel();
    await location._close();
    await networkMonitor._close();
    if (_closeBus) {
      await _bus.close();
    }
  }

  /// Generate a token for requests and sessions.
  String _generateToken() {
    final random = Random();
    String token;
    do {
      token = 'dart${random.nextInt(1 << 32)}';
    } while (_usedTokens.contains(token));
    _usedTokens.add(token);
    return token;
  }

  /// Record an active portal request.
  void _addRequest(DBusObjectPath path, _XdgPortalRequest request) {
    _requests[path] = request;
  }

  /// Record an active portal session.
  void _addSession(_XdgPortalSession session) {
    _sessions[session.path] = session;
  }
}
