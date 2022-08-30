import 'package:dbus/dbus.dart';

/// Details when a setting changes value.
class XdgSettingChangeEvent {
  /// The namespace of [key].
  final String namespace;

  /// The key that has changed.
  final String key;

  /// The new value for [key].
  final DBusValue value;

  const XdgSettingChangeEvent(this.namespace, this.key, this.value);

  @override
  int get hashCode => Object.hash(namespace, key, value);

  @override
  bool operator ==(other) =>
      other is XdgSettingChangeEvent &&
      other.namespace == namespace &&
      other.key == key &&
      other.value == value;

  @override
  String toString() => '$runtimeType($namespace, $key, $value)';
}

/// Portal to access system settings.
class XdgSettingsPortal {
  final DBusRemoteObject _object;

  XdgSettingsPortal(this._object);

  /// Stream of settings as they change.
  Stream<XdgSettingChangeEvent> get settingChanged =>
      DBusRemoteObjectSignalStream(
              object: _object,
              interface: 'org.freedesktop.portal.Settings',
              name: 'SettingChanged',
              signature: DBusSignature(('ssv')))
          .map((signal) => XdgSettingChangeEvent(signal.values[0].asString(),
              signal.values[1].asString(), signal.values[2].asVariant()));

  /// Get the version of this portal.
  Future<int> getVersion() => _object
      .getProperty('org.freedesktop.portal.Settings', 'version',
          signature: DBusSignature('u'))
      .then((v) => v.asUint32());

  /// Read a single value.
  Future<DBusValue> read(String namespace, String key) async {
    var result = await _object.callMethod('org.freedesktop.portal.Settings',
        'Read', [DBusString(namespace), DBusString(key)],
        replySignature: DBusSignature('v'));
    return result.returnValues[0].asVariant();
  }

  /// Read all the the settings in the given [namespaces].
  /// Globbing is allowed on trailing sections, e.g. 'com.example.*'.
  Future<Map<String, Map<String, DBusValue>>> readAll(
      Iterable<String> namespaces) async {
    var result = await _object.callMethod('org.freedesktop.portal.Settings',
        'ReadAll', [DBusArray.string(namespaces)],
        replySignature: DBusSignature('a{sa{sv}}'));
    return result.returnValues[0].asDict().map(
        (key, value) => MapEntry(key.asString(), value.asStringVariantDict()));
  }
}
