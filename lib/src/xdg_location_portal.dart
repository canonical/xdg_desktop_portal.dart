import 'dart:async';

import 'package:dbus/dbus.dart';

import 'xdg_portal_request.dart';
import 'xdg_portal_session.dart';

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

/// Provides a stream of locations using the portal APIs.
class _LocationStreamController {
  final DBusRemoteObject portalObject;
  final String Function() generateToken;
  late final StreamController<XdgLocation> controller;

  final int? distanceThreshold;
  final int? timeThreshold;
  final XdgLocationAccuracy? accuracy;
  final String parentWindow;

  StreamSubscription? _locationUpdatedSubscription;
  XdgPortalSession? session;
  StreamSubscription? _sessionSubscription;

  /// Locations received from the portal.
  Stream<XdgLocation> get stream => controller.stream;

  _LocationStreamController(
      {required this.portalObject,
      required this.generateToken,
      this.distanceThreshold,
      this.timeThreshold,
      this.accuracy,
      this.parentWindow = ''}) {
    controller =
        StreamController<XdgLocation>(onListen: _onListen, onCancel: _onCancel);
  }

  Future<void> _onListen() async {
    var locationUpdated = DBusSignalStream(portalObject.client,
        interface: 'org.freedesktop.portal.Location',
        name: 'LocationUpdated',
        path: portalObject.path,
        signature: DBusSignature('oa{sv}'));
    _locationUpdatedSubscription = locationUpdated.listen((signal) {
      var path = signal.values[0].asObjectPath();
      if (path != session?.object?.path) {
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

      controller.add(XdgLocation(
          latitude: getLocationValue('Latitude'),
          longitude: getLocationValue('Longitude'),
          altitude: getLocationValue('Altitude'),
          accuracy: getLocationValue('Accuracy'),
          speed: getLocationValue('Speed'),
          heading: getLocationValue('Heading'),
          timestamp: timestamp));
    });

    session = XdgPortalSession(portalObject, () async {
      var options = <String, DBusValue>{};
      options['session_handle_token'] = DBusString(generateToken());
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
      var createResult = await portalObject.callMethod(
          'org.freedesktop.portal.Location',
          'CreateSession',
          [DBusDict.stringVariant(options)],
          replySignature: DBusSignature('o'));
      return createResult.returnValues[0].asObjectPath();
    });
    _sessionSubscription = session!.stream.listen((_) {}, onDone: () async {
      await controller.close();
    });

    await session!.created;

    var startRequest = XdgPortalRequest(portalObject, () async {
      var options = <String, DBusValue>{};
      var result = await portalObject.callMethod(
          'org.freedesktop.portal.Location',
          'Start',
          [
            session!.object!.path,
            DBusString(parentWindow),
            DBusDict.stringVariant(options)
          ],
          replySignature: DBusSignature('o'));
      return result.returnValues[0].asObjectPath();
    });

    await startRequest.stream.first;
  }

  Future<void> _onCancel() async {
    await _locationUpdatedSubscription?.cancel();
    await _sessionSubscription?.cancel();
  }
}

/// Portal to get location information.
class XdgLocationPortal {
  final DBusRemoteObject _object;
  final String Function() _generateToken;

  XdgLocationPortal(this._object, this._generateToken);

  /// Get the version of this portal.
  Future<int> getVersion() => _object
      .getProperty('org.freedesktop.portal.Location', 'version',
          signature: DBusSignature('u'))
      .then((v) => v.asUint32());

  /// Create a location session that returns a stream of location updates from the portal.
  /// When the session is no longer required close the stream.
  Stream<XdgLocation> createSession(
      {int? distanceThreshold,
      int? timeThreshold,
      XdgLocationAccuracy? accuracy,
      String parentWindow = ''}) {
    var controller = _LocationStreamController(
        portalObject: _object,
        generateToken: _generateToken,
        distanceThreshold: distanceThreshold,
        timeThreshold: timeThreshold,
        accuracy: accuracy,
        parentWindow: parentWindow);
    return controller.stream;
  }
}
