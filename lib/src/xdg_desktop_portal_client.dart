import 'dart:async';
import 'dart:typed_data';
import 'package:dbus/dbus.dart';

/// A request sent to a portal.
class XdgPortalRequest {
  /// The client that is connected to this portal.
  XdgDesktopPortalClient client;

  late final DBusRemoteObject _object;

  XdgPortalRequest(this.client, DBusObjectPath path) {
    _object =
        DBusRemoteObject(client._bus, name: client._object.name, path: path);
  }

  /// Ends the user interaction with this request.
  Future<void> close() async {
    await _object.callMethod('org.freedesktop.impl.portal.Request', 'Close', [],
        replySignature: DBusSignature(''));
  }
}

/// Portal to send email.
class XdgEmailPortal {
  /// The client that is connected to this portal.
  XdgDesktopPortalClient client;

  XdgEmailPortal(this.client);

  /// Present a window to compose an email.
  Future<XdgPortalRequest> composeEmail(
      {String parentWindow = '',
      String? address,
      Iterable<String> addresses = const [],
      Iterable<String> cc = const [],
      Iterable<String> bcc = const [],
      String? subject,
      String? body}) async {
    var options = <String, DBusValue>{};
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
    return XdgPortalRequest(client, result.returnValues[0].asObjectPath());
  }
}

/// Portal to open URIs.
class XdgOpenUriPortal {
  /// The client that is connected to this portal.
  XdgDesktopPortalClient client;

  XdgOpenUriPortal(this.client);

  /// Ask to open a URI.
  Future<XdgPortalRequest> openUri(String uri,
      {String parentWindow = '',
      bool? writable,
      bool? ask,
      String? activationToken}) async {
    var options = <String, DBusValue>{};
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
    return XdgPortalRequest(client, result.returnValues[0].asObjectPath());
  }

  // FIXME: OpenFile

  // FIXME: OpenDirectory
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

  /// Portal to send email.
  late final XdgEmailPortal email;

  /// Portal to create notifications.
  late final XdgNotificationPortal notification;

  /// Portal to open URIs.
  late final XdgOpenUriPortal openUri;

  /// Portal to use system proxy.
  late final XdgProxyResolverPortal proxyResolver;

  /// Portal to access system settings.
  late final XdgSettingsPortal settings;

  /// Creates a new portal client. If [bus] is provided connect to the given D-Bus server.
  XdgDesktopPortalClient({DBusClient? bus})
      : _bus = bus ?? DBusClient.session(),
        _closeBus = bus == null {
    _object = DBusRemoteObject(_bus,
        name: 'org.freedesktop.portal.Desktop',
        path: DBusObjectPath('/org/freedesktop/portal/desktop'));
    email = XdgEmailPortal(this);
    notification = XdgNotificationPortal(this);
    openUri = XdgOpenUriPortal(this);
    proxyResolver = XdgProxyResolverPortal(this);
    settings = XdgSettingsPortal(this);
  }

  /// Terminates all active connections. If a client remains unclosed, the Dart process may not terminate.
  Future<void> close() async {
    if (_closeBus) {
      await _bus.close();
    }
  }
}
