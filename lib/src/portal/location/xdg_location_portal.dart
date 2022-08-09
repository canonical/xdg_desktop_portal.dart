import 'dart:async';

import 'package:dbus/dbus.dart';

import '../xdg_desktop_portal_client.dart';
import 'xdg_location.dart';
import 'xdg_location_accuracy.dart';
import 'xdg_location_session.dart';

/// Portal to get location information.
class XdgLocationPortal {
  /// The client that is connected to this portal.
  XdgDesktopPortalClient client;

  late final StreamSubscription _locationUpdatedSubscription;

  XdgLocationPortal(this.client) {
    var locationUpdated = DBusSignalStream(
      client.bus,
      interface: 'org.freedesktop.portal.Location',
      name: 'LocationUpdated',
      path: client.path,
      signature: DBusSignature('oa{sv}'),
    );
    _locationUpdatedSubscription = locationUpdated.listen(
      (signal) {
        var path = signal.values[0].asObjectPath();
        var session = client.sessions[path];
        if (session == null || session is! XdgLocationSession) {
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
        if (timestampValue != null &&
            timestampValue.signature == DBusSignature('(tt)')) {
          var values = timestampValue.asStruct();
          var s = values[0].asUint64();
          var us = values[1].asUint64();
          timestamp = DateTime.fromMicrosecondsSinceEpoch(s * 1000000 + us);
        }

        session.controller.add(
          XdgLocation(
            latitude: getLocationValue('Latitude'),
            longitude: getLocationValue('Longitude'),
            altitude: getLocationValue('Altitude'),
            accuracy: getLocationValue('Accuracy'),
            speed: getLocationValue('Speed'),
            heading: getLocationValue('Heading'),
            timestamp: timestamp,
          ),
        );
      },
    );
  }

  /// Create a location session that returns a stream of location updates from the portal.
  /// When the session is no longer required close the stream.
  Stream<XdgLocation> createSession({
    int? distanceThreshold,
    int? timeThreshold,
    XdgLocationAccuracy? accuracy,
    String parentWindow = '',
  }) {
    var controller = _LocationStreamController(
      client: client,
      distanceThreshold: distanceThreshold,
      timeThreshold: timeThreshold,
      accuracy: accuracy,
      parentWindow: parentWindow,
    );
    return controller.stream;
  }

  Future<void> close() async {
    await _locationUpdatedSubscription.cancel();
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

  XdgLocationSession? session;

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
    options['session_handle_token'] = DBusString(client.generateToken());
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
    var createResult = await client.callMethod(
      'org.freedesktop.portal.Location',
      'CreateSession',
      [DBusDict.stringVariant(options)],
      replySignature: DBusSignature('o'),
    );
    session = XdgLocationSession(
      client,
      createResult.returnValues[0].asObjectPath(),
      controller,
    );
    client.addSession(session!);
    var startRequest = await session!.start(parentWindow: parentWindow);
    await startRequest.checkSuccess();
  }

  Future<void> _onCancel() async {
    await session?.close();
  }
}
