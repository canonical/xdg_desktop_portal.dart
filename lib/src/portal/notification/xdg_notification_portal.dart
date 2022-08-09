import 'package:dbus/dbus.dart';

import '../xdg_desktop_portal_client.dart';
import 'xdg_notification_button.dart';
import 'xdg_notification_icon.dart';
import 'xdg_notification_priority.dart';

/// Portal to create notifications.
class XdgNotificationPortal {
  /// The client that is connected to this portal.
  XdgDesktopPortalClient client;

  XdgNotificationPortal(this.client);

  /// Send a notification.
  /// [id] can be used later to withdraw the notification with [removeNotification].
  /// If [id] is reused without withdrawing, the existing notification is replaced.
  Future<void> addNotification(
    String id, {
    String? title,
    String? body,
    XdgNotificationIcon? icon,
    XdgNotificationPriority? priority,
    String? defaultAction,
    List<XdgNotificationButton> buttons = const [],
  }) async {
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
    await client.callMethod(
      'org.freedesktop.portal.Notification',
      'AddNotification',
      [DBusString(id), DBusDict.stringVariant(notification)],
      replySignature: DBusSignature(''),
    );
  }

  /// Withdraw a notification created with [addNotification].
  Future<void> removeNotification(String id) async {
    await client.callMethod(
      'org.freedesktop.portal.Notification',
      'RemoveNotification',
      [DBusString(id)],
      replySignature: DBusSignature(''),
    );
  }
}
