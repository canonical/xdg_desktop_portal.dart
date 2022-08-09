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
