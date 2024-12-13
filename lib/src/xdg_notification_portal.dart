import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:dbus/dbus.dart';

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

/// An event that is emitted when a notification action is invoked.
class XdgNotificationActionInvokedEvent {
  /// Id of the notification that this action was invoked on.
  final String id;

  /// Name of the action that was invoked.
  final String action;

  /// Additional information.
  final List<DBusValue> parameter;

  XdgNotificationActionInvokedEvent(
      this.id, this.action, Iterable<DBusValue> parameter)
      : parameter = parameter.toList();

  @override
  int get hashCode => Object.hash(id, action, Object.hashAll(parameter));

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is XdgNotificationActionInvokedEvent &&
        other.id == id &&
        other.action == action &&
        listEquals(other.parameter, parameter);
  }

  @override
  String toString() => '$runtimeType($id, $action, $parameter)';
}

/// Portal to create notifications.
class XdgNotificationPortal {
  final DBusRemoteObject _object;

  XdgNotificationPortal(this._object);

  /// Get the version of this portal.
  Future<int> getVersion() => _object
      .getProperty('org.freedesktop.portal.Notification', 'version',
          signature: DBusSignature('u'))
      .then((v) => v.asUint32());

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
    await _object.callMethod(
        'org.freedesktop.portal.Notification',
        'AddNotification',
        [DBusString(id), DBusDict.stringVariant(notification)],
        replySignature: DBusSignature(''));
  }

  /// Withdraw a notification created with [addNotification].
  Future<void> removeNotification(String id) async {
    await _object.callMethod('org.freedesktop.portal.Notification',
        'RemoveNotification', [DBusString(id)],
        replySignature: DBusSignature(''));
  }

  /// Stream of invoked actions.
  Stream<XdgNotificationActionInvokedEvent> get actionInvoked =>
      DBusRemoteObjectSignalStream(
        object: _object,
        interface: 'org.freedesktop.portal.Notification',
        name: 'ActionInvoked',
        signature: DBusSignature(('ssav')),
      ).map((DBusSignal signal) {
        final id = signal.values[0].asString();
        final action = signal.values[1].asString();
        final parameter = signal.values[2].asVariantArray();
        return XdgNotificationActionInvokedEvent(id, action, parameter);
      });
}
