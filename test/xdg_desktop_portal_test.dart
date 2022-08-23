import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:dbus/dbus.dart';
import 'package:test/test.dart';
import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

class MockAccountDialog {
  final String parentWindow;
  final Map<String, DBusValue> options;

  MockAccountDialog(this.parentWindow, this.options);

  @override
  int get hashCode => Object.hash(
      parentWindow,
      Object.hashAll(
          options.entries.map((entry) => Object.hash(entry.key, entry.value))));

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    final mapEquals = const DeepCollectionEquality().equals;

    return other is MockAccountDialog &&
        other.parentWindow == parentWindow &&
        mapEquals(other.options, options);
  }

  @override
  String toString() => '$runtimeType($parentWindow, $options)';
}

class MockBackground {
  final String parentWindow;
  final Map<String, DBusValue> options;

  MockBackground(this.parentWindow, this.options);

  @override
  int get hashCode => Object.hash(
      parentWindow,
      Object.hashAll(
          options.entries.map((entry) => Object.hash(entry.key, entry.value))));

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    final mapEquals = const DeepCollectionEquality().equals;

    return other is MockBackground &&
        other.parentWindow == parentWindow &&
        mapEquals(other.options, options);
  }

  @override
  String toString() => '$runtimeType($parentWindow, $options)';
}

class MockCamera {
  final Map<String, DBusValue> options;

  MockCamera(this.options);

  @override
  int get hashCode => Object.hashAll(
      options.entries.map((entry) => Object.hash(entry.key, entry.value)));

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    final mapEquals = const DeepCollectionEquality().equals;

    return other is MockCamera && mapEquals(other.options, options);
  }

  @override
  String toString() => '$runtimeType($options)';
}

class MockDocument {
  final Uint8List path;
  int flags;
  late final Map<String, Set<String>> permissions;

  MockDocument(this.path,
      {this.flags = 0, Map<String, Set<String>>? permissions}) {
    this.permissions = permissions ?? {};
  }

  @override
  int get hashCode => Object.hash(
      Object.hashAll(path),
      flags,
      Object.hashAll(permissions.entries.map(
          (entry) => Object.hash(entry.key, Object.hashAll(entry.value)))));

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    final deepEquals = const DeepCollectionEquality().equals;

    return other is MockDocument &&
        deepEquals(other.path, path) &&
        other.flags == flags &&
        deepEquals(other.permissions, permissions);
  }

  @override
  String toString() =>
      '$runtimeType($path, flags: $flags, permissions: $permissions)';
}

class MockRemoteDesktop {
  final String parentWindow;
  final Map<String, DBusValue> options;

  MockRemoteDesktop(this.parentWindow, this.options);

  @override
  int get hashCode => Object.hash(
      parentWindow,
      Object.hashAll(
          options.entries.map((entry) => Object.hash(entry.key, entry.value))));

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    final mapEquals = const DeepCollectionEquality().equals;
    return other is MockRemoteDesktop &&
        other.parentWindow == parentWindow &&
        mapEquals(other.options, options);
  }

  @override
  String toString() => '$runtimeType($parentWindow, $options)';
}

class MockEmail {
  final String parentWindow;
  final Map<String, DBusValue> options;

  MockEmail(this.parentWindow, this.options);

  @override
  int get hashCode => Object.hash(
      parentWindow,
      Object.hashAll(
          options.entries.map((entry) => Object.hash(entry.key, entry.value))));

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    final mapEquals = const DeepCollectionEquality().equals;

    return other is MockEmail &&
        other.parentWindow == parentWindow &&
        mapEquals(other.options, options);
  }

  @override
  String toString() => '$runtimeType($parentWindow, $options)';
}

class MockUri {
  final String parentWindow;
  final String uri;
  final Map<String, DBusValue> options;

  MockUri(this.parentWindow, this.uri, this.options);

  @override
  int get hashCode => Object.hash(
      parentWindow,
      uri,
      Object.hashAll(
          options.entries.map((entry) => Object.hash(entry.key, entry.value))));

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    final mapEquals = const DeepCollectionEquality().equals;

    return other is MockUri &&
        other.parentWindow == parentWindow &&
        other.uri == uri &&
        mapEquals(other.options, options);
  }

  @override
  String toString() => '$runtimeType($uri, $options)';
}

class MockDialog {
  final String parentWindow;
  final String title;
  final Map<String, DBusValue> options;

  MockDialog(this.parentWindow, this.title, this.options);

  @override
  int get hashCode => Object.hash(
      parentWindow,
      title,
      Object.hashAll(
          options.entries.map((entry) => Object.hash(entry.key, entry.value))));

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    final mapEquals = const DeepCollectionEquality().equals;

    return other is MockDialog &&
        other.parentWindow == parentWindow &&
        other.title == title &&
        mapEquals(other.options, options);
  }

  @override
  String toString() => '$runtimeType($parentWindow, $title, $options)';
}

class MockLocationSession {
  String? parentWindow;
  final Map<String, DBusValue> options;

  MockLocationSession(this.parentWindow, this.options);

  @override
  int get hashCode => Object.hash(
      parentWindow,
      Object.hashAll(
          options.entries.map((entry) => Object.hash(entry.key, entry.value))));

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    final mapEquals = const DeepCollectionEquality().equals;

    return other is MockLocationSession &&
        other.parentWindow == parentWindow &&
        mapEquals(other.options, options);
  }

  @override
  String toString() => '$runtimeType($parentWindow, $options)';
}

class MockPortalRequestObject extends DBusObject {
  final MockPortalDesktopServer server;
  Future<void> Function()? onClosed;

  MockPortalRequestObject(
      this.server, String sender, String token, this.onClosed)
      : super(DBusObjectPath(
            '/org/freedesktop/portal/desktop/request/${sender.substring(1).replaceAll('.', '_')}/$token'));

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != 'org.freedesktop.portal.Request') {
      return DBusMethodErrorResponse.unknownInterface();
    }

    if (methodCall.name == 'Close') {
      if (onClosed != null) {
        await onClosed!();
      }
      await server.removeRequest(this);
      return DBusMethodSuccessResponse();
    } else {
      return DBusMethodErrorResponse.unknownMethod();
    }
  }

  Future<void> respond(
      {int response = 0, Map<String, DBusValue> result = const {}}) async {
    await emitSignal('org.freedesktop.portal.Request', 'Response',
        [DBusUint32(response), DBusDict.stringVariant(result)]);
    await server.removeRequest(this);
  }
}

class MockPortalSessionObject extends DBusObject {
  final MockPortalDesktopServer server;

  MockPortalSessionObject(this.server, String token)
      : super(DBusObjectPath('/org/freedesktop/portal/desktop/session/$token'));

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != 'org.freedesktop.portal.Session') {
      return DBusMethodErrorResponse.unknownInterface();
    }

    if (methodCall.name == 'Close') {
      await emitSignal('org.freedesktop.portal.Session', 'Closed');
      await server.removeSession(this);
      return DBusMethodSuccessResponse();
    } else {
      return DBusMethodErrorResponse.unknownMethod();
    }
  }
}

class MockPortalDesktopObject extends DBusObject {
  final MockPortalDesktopServer server;

  MockPortalDesktopObject(this.server)
      : super(DBusObjectPath('/org/freedesktop/portal/desktop'));

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    switch (methodCall.interface) {
      case 'org.freedesktop.portal.Account':
        return handleAccountMethodCall(methodCall);
      case 'org.freedesktop.portal.Background':
        return handleBackgroundMethodCall(methodCall);
      case 'org.freedesktop.portal.Camera':
        return handleCameraMethodCall(methodCall);
      case 'org.freedesktop.portal.Email':
        return handleEmailMethodCall(methodCall);
      case 'org.freedesktop.portal.FileChooser':
        return handleFileChooserMethodCall(methodCall);
      case 'org.freedesktop.portal.Location':
        return handleLocationMethodCall(methodCall);
      case 'org.freedesktop.portal.NetworkMonitor':
        return handleNetworkMonitorMethodCall(methodCall);
      case 'org.freedesktop.portal.Notification':
        return handleNotificationMethodCall(methodCall);
      case 'org.freedesktop.portal.OpenURI':
        return handleOpenURIMethodCall(methodCall);
      case 'org.freedesktop.portal.ProxyResolver':
        return handleProxyResolverMethodCall(methodCall);
      case 'org.freedesktop.portal.RemoteDesktop':
        return handleRemoteDesktopMethodCall(methodCall);
      case 'org.freedesktop.portal.Secret':
        return handleSecretMethodCall(methodCall);
      case 'org.freedesktop.portal.Settings':
        return handleSettingsMethodCall(methodCall);
      default:
        return DBusMethodErrorResponse.unknownInterface();
    }
  }

  Future<DBusMethodResponse> handleAccountMethodCall(
      DBusMethodCall methodCall) async {
    switch (methodCall.name) {
      case 'GetUserInformation':
        var parentWindow = methodCall.values[0].asString();
        var options = methodCall.values[1].asStringVariantDict();
        var token =
            options['handle_token']?.asString() ?? server.generateToken();
        options.removeWhere((key, value) => key == 'handle_token');
        var dialog = MockAccountDialog(parentWindow, options);
        server.accountDialogs.add(dialog);
        var request = await server.addRequest(methodCall.sender, token,
            onClosed: () async {
          server.accountDialogs.remove(dialog);
        });
        if (server.userId != null &&
            server.userName != null &&
            server.userImage != null) {
          Future.delayed(
              Duration.zero,
              () async => await request.respond(result: {
                    'id': DBusString(server.userId!),
                    'name': DBusString(server.userName!),
                    'image': DBusString(server.userImage!),
                  }));
        }
        return DBusMethodSuccessResponse([request.path]);
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  Future<DBusMethodResponse> handleBackgroundMethodCall(
      DBusMethodCall methodCall) async {
    switch (methodCall.name) {
      case 'RequestBackground':
        var parentWindow = methodCall.values[0].asString();
        var options = methodCall.values[1].asStringVariantDict();
        server.background.add(MockBackground(parentWindow, options));
        var token =
            options['handle_token']?.asString() ?? server.generateToken();
        options.removeWhere((key, value) => key == 'handle_token');
        var request = await server.addRequest(methodCall.sender, token);
        Future.delayed(
            Duration.zero,
            () async => await request.respond(result: {
                  'background': DBusBoolean(true),
                  'autostart':
                      DBusBoolean(options['autostart']?.asBoolean() ?? false),
                }));

        return DBusMethodSuccessResponse([request.path]);
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  Future<DBusMethodResponse> handleCameraMethodCall(
      DBusMethodCall methodCall) async {
    switch (methodCall.name) {
      case 'AccessCamera':
        var options = methodCall.values[0].asStringVariantDict();
        server.camera.add(MockCamera(options));
        var token =
            options['handle_token']?.asString() ?? server.generateToken();
        options.removeWhere((key, value) => key == 'handle_token');
        var request = await server.addRequest(methodCall.sender, token);
        Future.delayed(Duration.zero, () async => await request.respond());
        return DBusMethodSuccessResponse([request.path]);
      case 'OpenPipeWireRemote':
        var handle = DBusUnixFd(ResourceHandle.fromStdin(stdin));
        return DBusMethodSuccessResponse([handle]);
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  Future<DBusMethodResponse> handleEmailMethodCall(
      DBusMethodCall methodCall) async {
    switch (methodCall.name) {
      case 'ComposeEmail':
        var parentWindow = methodCall.values[0].asString();
        var options = methodCall.values[1].asStringVariantDict();
        server.composedEmails.add(MockEmail(parentWindow, options));
        var token =
            options['handle_token']?.asString() ?? server.generateToken();
        options.removeWhere((key, value) => key == 'handle_token');
        var request = await server.addRequest(methodCall.sender, token);
        Future.delayed(Duration.zero, () async => await request.respond());
        return DBusMethodSuccessResponse([request.path]);
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  Future<DBusMethodResponse> handleFileChooserMethodCall(
      DBusMethodCall methodCall) async {
    switch (methodCall.name) {
      case 'OpenFile':
        var parentWindow = methodCall.values[0].asString();
        var title = methodCall.values[1].asString();
        var options = methodCall.values[2].asStringVariantDict();
        var token =
            options['handle_token']?.asString() ?? server.generateToken();
        options.removeWhere((key, value) => key == 'handle_token');
        var dialog = MockDialog(parentWindow, title, options);
        server.openFileDialogs.add(dialog);
        var request = await server.addRequest(methodCall.sender, token,
            onClosed: () async {
          server.openFileDialogs.remove(dialog);
        });
        if (server.openFileResponse != null) {
          Future.delayed(
              Duration.zero,
              () async => await request.respond(
                  response: server.openFileResponse!.response,
                  result: server.openFileResponse!.result));
        }
        return DBusMethodSuccessResponse([request.path]);
      case 'SaveFile':
        var parentWindow = methodCall.values[0].asString();
        var title = methodCall.values[1].asString();
        var options = methodCall.values[2].asStringVariantDict();
        var token =
            options['handle_token']?.asString() ?? server.generateToken();
        options.removeWhere((key, value) => key == 'handle_token');
        var dialog = MockDialog(parentWindow, title, options);
        server.saveFileDialogs.add(dialog);
        var request = await server.addRequest(methodCall.sender, token,
            onClosed: () async {
          server.saveFileDialogs.remove(dialog);
        });
        if (server.saveFileResponse != null) {
          Future.delayed(
              Duration.zero,
              () async => await request.respond(
                  response: server.saveFileResponse!.response,
                  result: server.saveFileResponse!.result));
        }
        return DBusMethodSuccessResponse([request.path]);
      case 'SaveFiles':
        var parentWindow = methodCall.values[0].asString();
        var title = methodCall.values[1].asString();
        var options = methodCall.values[2].asStringVariantDict();
        var token =
            options['handle_token']?.asString() ?? server.generateToken();
        options.removeWhere((key, value) => key == 'handle_token');
        var dialog = MockDialog(parentWindow, title, options);
        server.saveFilesDialogs.add(dialog);
        var request = await server.addRequest(methodCall.sender, token,
            onClosed: () async {
          server.saveFilesDialogs.remove(dialog);
        });
        if (server.saveFilesResponse != null) {
          Future.delayed(
              Duration.zero,
              () async => await request.respond(
                  response: server.saveFilesResponse!.response,
                  result: server.saveFilesResponse!.result));
        }
        return DBusMethodSuccessResponse([request.path]);
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  Future<DBusMethodResponse> handleLocationMethodCall(
      DBusMethodCall methodCall) async {
    switch (methodCall.name) {
      case 'CreateSession':
        var options = methodCall.values[0].asStringVariantDict();
        var token = options['session_handle_token']?.asString();
        if (token == null) {
          return DBusMethodErrorResponse.invalidArgs('Missing token');
        }
        options.removeWhere((key, value) => key == 'session_handle_token');
        var locationSession = MockLocationSession(null, options);
        var session = await server.addSession(token);
        server._locationSessions[session.path] = locationSession;
        return DBusMethodSuccessResponse([session.path]);
      case 'Start':
        var path = methodCall.values[0].asObjectPath();
        var parentWindow = methodCall.values[1].asString();
        var session = server.sessions[path];
        var locationSession = server._locationSessions[path];
        if (locationSession != null) {
          locationSession.parentWindow = parentWindow;
        }
        var options = methodCall.values[2].asStringVariantDict();
        var token =
            options['handle_token']?.asString() ?? server.generateToken();
        var request = await server.addRequest(methodCall.sender, token);
        Future.delayed(Duration.zero, () async {
          await request.respond();
          for (var location in server.locations) {
            await emitSignal('org.freedesktop.portal.Location',
                'LocationUpdated', [path, DBusDict.stringVariant(location)]);
          }
          if (server.closeLocationSession) {
            await server.removeSession(session!, emitClosed: true);
          }
        });
        return DBusMethodSuccessResponse([request.path]);
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  Future<DBusMethodResponse> handleNetworkMonitorMethodCall(
      DBusMethodCall methodCall) async {
    switch (methodCall.name) {
      case 'GetStatus':
        var status = <String, DBusValue>{};
        status['available'] = DBusBoolean(server.networkAvailable);
        status['metered'] = DBusBoolean(server.networkMetered);
        status['connectivity'] = DBusUint32(server.networkConnectivity);
        return DBusMethodSuccessResponse([DBusDict.stringVariant(status)]);
      case 'CanReach':
        var hostname = methodCall.values[0].asString();
        var port = methodCall.values[1].asUint32();
        var canReach = true;
        if (hostname == 'unreachable.com' && port == 99) {
          canReach = false;
        }
        return DBusMethodSuccessResponse([DBusBoolean(canReach)]);
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  Future<DBusMethodResponse> handleNotificationMethodCall(
      DBusMethodCall methodCall) async {
    switch (methodCall.name) {
      case 'AddNotification':
        var id = methodCall.values[0].asString();
        var notification = methodCall.values[1].asStringVariantDict();
        server.notifications[id] = notification;
        return DBusMethodSuccessResponse();
      case 'RemoveNotification':
        var id = methodCall.values[0].asString();
        server.notifications.remove(id);
        return DBusMethodSuccessResponse();
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  Future<DBusMethodResponse> handleOpenURIMethodCall(
      DBusMethodCall methodCall) async {
    switch (methodCall.name) {
      case 'OpenURI':
        var parentWindow = methodCall.values[0].asString();
        var uri = methodCall.values[1].asString();
        var options = methodCall.values[2].asStringVariantDict();
        var token =
            options['handle_token']?.asString() ?? server.generateToken();
        options.removeWhere((key, value) => key == 'handle_token');
        server.openedUris.add(MockUri(parentWindow, uri, options));
        var request = await server.addRequest(methodCall.sender, token);
        Future.delayed(Duration.zero, () async => await request.respond());
        return DBusMethodSuccessResponse([request.path]);
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  Future<DBusMethodResponse> handleProxyResolverMethodCall(
      DBusMethodCall methodCall) async {
    switch (methodCall.name) {
      case 'Lookup':
        var uri = methodCall.values[0].asString();
        var proxies = server.proxies[uri] ?? ['direct://'];
        return DBusMethodSuccessResponse([DBusArray.string(proxies)]);
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  Future<DBusMethodResponse> handleRemoteDesktopMethodCall(
      DBusMethodCall methodCall) async {
    switch (methodCall.name) {
      case 'CreateSession':
        var options = methodCall.values[0].asStringVariantDict();
        server.remoteDesktop.add(MockRemoteDesktop('', options));
        var token =
            options['handle_token']?.asString() ?? server.generateToken();
        options.removeWhere((key, value) => key == 'handle_token');
        options.removeWhere((key, value) => key == 'session_handle_token');
        var request = await server.addRequest(methodCall.sender, token);
        Future.delayed(
            Duration.zero,
            () async => await request.respond(result: <String, DBusValue>{
                  'session_handle':
                      DBusString(server.remoteDesktopSessionHandle!)
                }));
        return DBusMethodSuccessResponse([request.path]);
      case 'SelectDevices':
        var options = methodCall.values[1].asStringVariantDict();
        server.remoteDesktopSelectedDivice = options['types']?.asUint32();
        server.remoteDesktop.add(MockRemoteDesktop('', options));
        var token =
            options['handle_token']?.asString() ?? server.generateToken();
        options.removeWhere((key, value) => key == 'handle_token');
        var request = await server.addRequest(methodCall.sender, token);
        Future.delayed(Duration.zero, () async => await request.respond());
        return DBusMethodSuccessResponse([request.path]);
      case 'Start':
        var parentWindow = methodCall.values[1].asString();
        var options = methodCall.values[2].asStringVariantDict();
        server.remoteDesktop.add(MockRemoteDesktop(parentWindow, options));
        var token =
            options['handle_token']?.asString() ?? server.generateToken();
        options.removeWhere((key, value) => key == 'handle_token');
        var request = await server.addRequest(methodCall.sender, token);
        var result = <String, DBusValue>{};
        result['devices'] = DBusUint32(server.remoteDesktopSelectedDivice ?? 0);
        Future.delayed(
            Duration.zero, () async => await request.respond(result: result));
        return DBusMethodSuccessResponse([request.path]);
      case 'NotifyPointerMotion':
        if (server.remoteDesktopSelectedDivice != null &&
            server.remoteDesktopSelectedDivice! & 2 != 0) {
          server.remoteDesktop.add(MockRemoteDesktop(
              '', {'dx': methodCall.values[2], 'dy': methodCall.values[3]}));
          return DBusMethodSuccessResponse();
        } else {
          return DBusMethodErrorResponse.failed(
              "Session doesn't have access to a device of type: pointer");
        }
      case 'NotifyPointerMotionAbsolute':
        if (server.remoteDesktopSelectedDivice != null &&
            server.remoteDesktopSelectedDivice! & 2 != 0) {
          server.remoteDesktop.add(MockRemoteDesktop('', {
            'stream': methodCall.values[2],
            'x': methodCall.values[3],
            'y': methodCall.values[4]
          }));
          return DBusMethodSuccessResponse();
        } else {
          return DBusMethodErrorResponse.failed(
              "Session doesn't have access to a device of type: pointer");
        }
      case 'NotifyPointerButton':
        if (server.remoteDesktopSelectedDivice != null &&
            server.remoteDesktopSelectedDivice! & 2 != 0) {
          server.remoteDesktop.add(MockRemoteDesktop('',
              {'button': methodCall.values[2], 'state': methodCall.values[3]}));
          return DBusMethodSuccessResponse();
        } else {
          return DBusMethodErrorResponse.failed(
              "Session doesn't have access to a device of type: pointer");
        }
      case 'NotifyPointerAxis':
        if (server.remoteDesktopSelectedDivice != null &&
            server.remoteDesktopSelectedDivice! & 2 != 0) {
          server.remoteDesktop.add(MockRemoteDesktop(
              '', {'dx': methodCall.values[2], 'dy': methodCall.values[3]}));
          return DBusMethodSuccessResponse();
        } else {
          return DBusMethodErrorResponse.failed(
              "Session doesn't have access to a device of type: pointer");
        }
      case 'NotifyPointerAxisDiscrete':
        if (server.remoteDesktopSelectedDivice != null &&
            server.remoteDesktopSelectedDivice! & 2 != 0) {
          server.remoteDesktop.add(MockRemoteDesktop('',
              {'axis': methodCall.values[2], 'steps': methodCall.values[3]}));
          return DBusMethodSuccessResponse();
        } else {
          return DBusMethodErrorResponse.failed(
              "Session doesn't have access to a device of type: pointer");
        }
      case 'NotifyKeyboardKeycode':
        if (server.remoteDesktopSelectedDivice != null &&
            server.remoteDesktopSelectedDivice! & 1 != 0) {
          server.remoteDesktop.add(MockRemoteDesktop('', {
            'keycode': methodCall.values[2],
            'state': methodCall.values[3]
          }));
          return DBusMethodSuccessResponse();
        } else {
          return DBusMethodErrorResponse.failed(
              "Session doesn't have access to a device of type: keyboard");
        }
      case 'NotifyKeyboardKeysym':
        if (server.remoteDesktopSelectedDivice != null &&
            server.remoteDesktopSelectedDivice! & 1 != 0) {
          server.remoteDesktop.add(MockRemoteDesktop('',
              {'keysym': methodCall.values[2], 'state': methodCall.values[3]}));
          return DBusMethodSuccessResponse();
        } else {
          return DBusMethodErrorResponse.failed(
              "Session doesn't have access to a device of type: keyboard");
        }
      case 'NotifyTouchDown':
        if (server.remoteDesktopSelectedDivice != null &&
            server.remoteDesktopSelectedDivice! & 4 != 0) {
          server.remoteDesktop.add(MockRemoteDesktop('', {
            'stream': methodCall.values[2],
            'slot': methodCall.values[3],
            'x': methodCall.values[4],
            'y': methodCall.values[5],
          }));
          return DBusMethodSuccessResponse();
        } else {
          return DBusMethodErrorResponse.failed(
              "Session doesn't have access to a device of type: touch");
        }
      case 'NotifyTouchMotion':
        if (server.remoteDesktopSelectedDivice != null &&
            server.remoteDesktopSelectedDivice! & 4 != 0) {
          server.remoteDesktop.add(MockRemoteDesktop('', {
            'stream': methodCall.values[2],
            'slot': methodCall.values[3],
            'x': methodCall.values[4],
            'y': methodCall.values[5],
          }));
          return DBusMethodSuccessResponse();
        } else {
          return DBusMethodErrorResponse.failed(
              "Session doesn't have access to a device of type: touch");
        }
      case 'NotifyTouchUp':
        if (server.remoteDesktopSelectedDivice != null &&
            server.remoteDesktopSelectedDivice! & 4 != 0) {
          server.remoteDesktop
              .add(MockRemoteDesktop('', {'slot': methodCall.values[2]}));
          return DBusMethodSuccessResponse();
        } else {
          return DBusMethodErrorResponse.failed(
              "Session doesn't have access to a device of type: touch");
        }

      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  Future<DBusMethodResponse> handleSecretMethodCall(
      DBusMethodCall methodCall) async {
    switch (methodCall.name) {
      case 'RetrieveSecret':
        var handle = methodCall.values[0].asUnixFd();
        await handle.toFile().writeFrom(server.secret);
        var options = methodCall.values[1].asStringVariantDict();
        var token =
            options['handle_token']?.asString() ?? server.generateToken();
        options.removeWhere((key, value) => key == 'handle_token');
        var request = await server.addRequest(methodCall.sender, token);
        Future.delayed(Duration.zero, () async => await request.respond());
        return DBusMethodSuccessResponse([request.path]);
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  Future<DBusMethodResponse> handleSettingsMethodCall(
      DBusMethodCall methodCall) async {
    switch (methodCall.name) {
      case 'Read':
        var namespace = methodCall.values[0].asString();
        var namespaceValues = server.settingsValues[namespace] ?? {};
        var key = methodCall.values[1].asString();
        var value = namespaceValues[key];
        if (value == null) {
          return DBusMethodErrorResponse(
              'org.freedesktop.portal.Error.NotFound',
              [DBusString('Requested setting not found')]);
        }
        return DBusMethodSuccessResponse([DBusVariant(value)]);
      case 'ReadAll':
        var namespaces = methodCall.values[0].asStringArray();
        var result = <DBusValue, DBusValue>{};
        for (var namespace in namespaces) {
          var settingsValues = server.settingsValues[namespace];
          if (settingsValues != null) {
            result[DBusString(namespace)] =
                DBusDict.stringVariant(settingsValues);
          }
        }
        return DBusMethodSuccessResponse(
            [DBusDict(DBusSignature('s'), DBusSignature('a{sv}'), result)]);
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    switch (interface) {
      case 'org.freedesktop.portal.Account':
        return getAccountProperty(name);
      case 'org.freedesktop.portal.Background':
        return getBackgroundProperty(name);
      case 'org.freedesktop.portal.Camera':
        return getCameraProperty(name);
      case 'org.freedesktop.portal.Email':
        return getEmailProperty(name);
      case 'org.freedesktop.portal.FileChooser':
        return getFileChooserProperty(name);
      case 'org.freedesktop.portal.Location':
        return getLocationProperty(name);
      case 'org.freedesktop.portal.NetworkMonitor':
        return getNetworkMonitorProperty(name);
      case 'org.freedesktop.portal.Notification':
        return getNotificationProperty(name);
      case 'org.freedesktop.portal.OpenURI':
        return getOpenURIProperty(name);
      case 'org.freedesktop.portal.ProxyResolver':
        return getProxyResolverProperty(name);
      case 'org.freedesktop.portal.RemoteDesktop':
        return getRemoteDesktopProperty(name);
      case 'org.freedesktop.portal.Secret':
        return getSecretProperty(name);
      case 'org.freedesktop.portal.Settings':
        return getSettingsProperty(name);
      default:
        return DBusMethodErrorResponse.unknownProperty();
    }
  }

  Future<DBusMethodResponse> getAccountProperty(String name) async {
    switch (name) {
      case 'version':
        return DBusGetPropertyResponse(DBusUint32(1));
      default:
        return DBusMethodErrorResponse.unknownProperty();
    }
  }

  Future<DBusMethodResponse> getBackgroundProperty(String name) async {
    switch (name) {
      case 'version':
        return DBusGetPropertyResponse(DBusUint32(1));
      default:
        return DBusMethodErrorResponse.unknownProperty();
    }
  }

  Future<DBusMethodResponse> getCameraProperty(String name) async {
    switch (name) {
      case 'version':
        return DBusGetPropertyResponse(DBusUint32(1));
      default:
        return DBusMethodErrorResponse.unknownProperty();
    }
  }

  Future<DBusMethodResponse> getEmailProperty(String name) async {
    switch (name) {
      case 'version':
        return DBusGetPropertyResponse(DBusUint32(3));
      default:
        return DBusMethodErrorResponse.unknownProperty();
    }
  }

  Future<DBusMethodResponse> getFileChooserProperty(String name) async {
    switch (name) {
      case 'version':
        return DBusGetPropertyResponse(DBusUint32(1));
      default:
        return DBusMethodErrorResponse.unknownProperty();
    }
  }

  Future<DBusMethodResponse> getLocationProperty(String name) async {
    switch (name) {
      case 'version':
        return DBusGetPropertyResponse(DBusUint32(1));
      default:
        return DBusMethodErrorResponse.unknownProperty();
    }
  }

  Future<DBusMethodResponse> getNetworkMonitorProperty(String name) async {
    switch (name) {
      case 'version':
        return DBusGetPropertyResponse(DBusUint32(3));
      default:
        return DBusMethodErrorResponse.unknownProperty();
    }
  }

  Future<DBusMethodResponse> getNotificationProperty(String name) async {
    switch (name) {
      case 'version':
        return DBusGetPropertyResponse(DBusUint32(1));
      default:
        return DBusMethodErrorResponse.unknownProperty();
    }
  }

  Future<DBusMethodResponse> getOpenURIProperty(String name) async {
    switch (name) {
      case 'version':
        return DBusGetPropertyResponse(DBusUint32(3));
      default:
        return DBusMethodErrorResponse.unknownProperty();
    }
  }

  Future<DBusMethodResponse> getProxyResolverProperty(String name) async {
    switch (name) {
      case 'version':
        return DBusGetPropertyResponse(DBusUint32(1));
      default:
        return DBusMethodErrorResponse.unknownProperty();
    }
  }

  Future<DBusMethodResponse> getRemoteDesktopProperty(String name) async {
    switch (name) {
      case 'version':
        return DBusGetPropertyResponse(DBusUint32(1));
      case 'AvailableDeviceTypes':
        return DBusGetPropertyResponse(DBusUint32(7));
      default:
        return DBusMethodErrorResponse.unknownProperty();
    }
  }

  Future<DBusMethodResponse> getSecretProperty(String name) async {
    switch (name) {
      case 'version':
        return DBusGetPropertyResponse(DBusUint32(1));
      default:
        return DBusMethodErrorResponse.unknownProperty();
    }
  }

  Future<DBusMethodResponse> getSettingsProperty(String name) async {
    switch (name) {
      case 'version':
        return DBusGetPropertyResponse(DBusUint32(1));
      default:
        return DBusMethodErrorResponse.unknownProperty();
    }
  }
}

class MockPortalDocumentsObject extends DBusObject {
  final MockPortalDocumentsServer server;

  MockPortalDocumentsObject(this.server)
      : super(DBusObjectPath('/org/freedesktop/portal/documents'));

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    switch (methodCall.interface) {
      case 'org.freedesktop.portal.Documents':
        return handleDocumentsMethodCall(methodCall);
      default:
        return DBusMethodErrorResponse.unknownInterface();
    }
  }

  Future<DBusMethodResponse> handleDocumentsMethodCall(
      DBusMethodCall methodCall) async {
    switch (methodCall.name) {
      case 'GetMountPoint':
        return DBusMethodSuccessResponse(
            [DBusArray.byte(server.mountPoint ?? Uint8List(0))]);
      case 'AddFull':
        var handles = methodCall.values[0].asUnixFdArray();
        var flags = methodCall.values[1].asUint32();
        var appId = methodCall.values[2].asString();
        var permissions = <String, Set<String>>{};
        if (appId != '') {
          permissions[appId] =
              Set<String>.from(methodCall.values[3].asStringArray());
        }
        var docIds = <String>[];
        for (var handle in handles) {
          var file = handle.toFile();
          // The real documents portal gets the path from /proc/self/fd, for tests we will use the file contents.
          var path = await file.read(1024);
          var docId = server.addDocument(
              MockDocument(path, flags: flags, permissions: permissions));
          await file.close();
          docIds.add(docId);
        }
        return DBusMethodSuccessResponse(
            [DBusArray.string(docIds), DBusDict.stringVariant({})]);
      case 'GrantPermissions':
        var docId = methodCall.values[0].asString();
        var appId = methodCall.values[1].asString();
        var permissions = methodCall.values[2].asStringArray();
        var doc = server.documents[docId]!;
        if (doc.permissions[appId] == null) {
          doc.permissions[appId] = {};
        }
        doc.permissions[appId]!.addAll(permissions);
        return DBusMethodSuccessResponse();
      case 'RevokePermissions':
        var docId = methodCall.values[0].asString();
        var appId = methodCall.values[1].asString();
        var permissions = methodCall.values[2].asStringArray();
        var doc = server.documents[docId]!;
        for (var p in permissions) {
          doc.permissions[appId]?.remove(p);
        }
        return DBusMethodSuccessResponse();
      case 'Delete':
        var docId = methodCall.values[0].asString();
        server.documents.remove(docId);
        return DBusMethodSuccessResponse();
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    switch (interface) {
      case 'org.freedesktop.portal.Documents':
        return getDocumentsProperty(name);
      default:
        return DBusMethodErrorResponse.unknownProperty();
    }
  }

  Future<DBusMethodResponse> getDocumentsProperty(String name) async {
    switch (name) {
      case 'version':
        return DBusGetPropertyResponse(DBusUint32(4));
      default:
        return DBusMethodErrorResponse.unknownProperty();
    }
  }
}

class MockRequestResponse {
  final int response;
  final Map<String, DBusValue> result;

  MockRequestResponse(this.response, this.result);
}

class MockPortalDesktopServer extends DBusClient {
  late final MockPortalDesktopObject _root;

  final requests = <MockPortalRequestObject>[];
  final sessions = <DBusObjectPath, MockPortalSessionObject>{};
  final usedTokens = <String>{};

  final String? userId;
  final String? userName;
  final String? userImage;
  final MockRequestResponse? openFileResponse;
  final MockRequestResponse? saveFileResponse;
  final MockRequestResponse? saveFilesResponse;
  late final Map<String, Map<String, DBusValue>> notifications;
  final Map<String, List<String>> proxies;
  final Map<String, Map<String, DBusValue>> settingsValues;
  final List<Map<String, DBusValue>> locations;
  final bool closeLocationSession;
  bool networkAvailable;
  bool networkMetered;
  int networkConnectivity;
  List<int> secret;
  final String? remoteDesktopSessionHandle;
  late final int? remoteDesktopSelectedDivice;

  final accountDialogs = <MockAccountDialog>[];
  final background = <MockBackground>[];
  final camera = <MockCamera>[];
  final composedEmails = <MockEmail>[];
  final openedUris = <MockUri>[];
  final openFileDialogs = <MockDialog>[];
  final saveFileDialogs = <MockDialog>[];
  final saveFilesDialogs = <MockDialog>[];
  Iterable<MockLocationSession> get locationSessions =>
      _locationSessions.values;
  final _locationSessions = <DBusObjectPath, MockLocationSession>{};
  final remoteDesktop = <MockRemoteDesktop>[];

  MockPortalDesktopServer(
    DBusAddress clientAddress, {
    this.userId,
    this.userName,
    this.userImage,
    this.openFileResponse,
    this.saveFileResponse,
    this.saveFilesResponse,
    Map<String, Map<String, DBusValue>>? notifications,
    this.proxies = const {},
    this.settingsValues = const {},
    this.locations = const [],
    this.closeLocationSession = false,
    this.networkAvailable = true,
    this.networkMetered = false,
    this.networkConnectivity = 3,
    this.remoteDesktopSessionHandle,
    this.secret = const [],
  }) : super(clientAddress) {
    _root = MockPortalDesktopObject(this);
    this.notifications = notifications ?? {};
  }

  Future<void> start() async {
    await requestName('org.freedesktop.portal.Desktop');
    await registerObject(_root);
  }

  Future<void> setNetworkStatus(
      {bool? available, bool? metered, int? connectivity}) async {
    if (available != null) {
      networkAvailable = available;
    }
    if (metered != null) {
      networkMetered = metered;
    }
    if (connectivity != null) {
      networkConnectivity = connectivity;
    }
    await _root.emitSignal('org.freedesktop.portal.NetworkMonitor', 'changed');
  }

  /// Generate a token for requests and sessions.
  String generateToken() {
    final random = Random();
    String token;
    do {
      token = '${random.nextInt(1 << 32)}';
    } while (usedTokens.contains(token));
    usedTokens.add(token);
    return token;
  }

  Future<MockPortalRequestObject> addRequest(String sender, String token,
      {Future<void> Function()? onClosed}) async {
    var request = MockPortalRequestObject(this, sender, token, onClosed);
    await registerObject(request);
    return request;
  }

  Future<void> removeRequest(MockPortalRequestObject request) async {
    requests.remove(request);
    await unregisterObject(request);
  }

  Future<MockPortalSessionObject> addSession(String token) async {
    var session = MockPortalSessionObject(this, token);
    sessions[session.path] = session;
    await registerObject(session);
    return session;
  }

  Future<void> removeSession(MockPortalSessionObject session,
      {var emitClosed = false}) async {
    if (emitClosed) {
      await session.emitSignal('org.freedesktop.portal.Session', 'Closed');
    }
    sessions.remove(session.path);
    await unregisterObject(session);
  }
}

class MockPortalDocumentsServer extends DBusClient {
  late final MockPortalDocumentsObject _root;

  final Uint8List? mountPoint;
  late final Map<String, MockDocument> documents;

  MockPortalDocumentsServer(DBusAddress clientAddress,
      {this.mountPoint, Map<String, MockDocument>? documents})
      : super(clientAddress) {
    this.documents = documents ?? {};
    _root = MockPortalDocumentsObject(this);
  }

  Future<void> start() async {
    await requestName('org.freedesktop.portal.Documents');
    await registerObject(_root);
  }

  String addDocument(MockDocument document) {
    final random = Random();
    while (true) {
      var token = '${random.nextInt(9999999)}';
      if (!documents.containsKey(token)) {
        documents[token] = document;
        return token;
      }
    }
  }
}

void main() {
  test('account', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(
      clientAddress,
      userId: 'alice',
      userName: 'alice',
      userImage: 'file://home/me/image.png',
    );
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    expect(await client.account.getVersion(), equals(1));

    var userInformation = await client.account
        .getUserInformation(
            parentWindow: 'x11:12345',
            reason:
                'Allows your personal information to be included with recipes you share with your friends.')
        .first;
    expect(
        portalServer.accountDialogs,
        equals([
          MockAccountDialog('x11:12345', {
            'reason': DBusString(
                'Allows your personal information to be included with recipes you share with your friends.'),
          })
        ]));
    expect(
      userInformation,
      equals(
        XdgAccountUserInformation(
          id: 'alice',
          name: 'alice',
          image: 'file://home/me/image.png',
        ),
      ),
    );
    expect(
        userInformation.toString(),
        equals(
            'XdgAccountUserInformation(id: alice, name: alice, image: file://home/me/image.png)'));
    expect(
        userInformation.hashCode,
        equals(XdgAccountUserInformation(
          id: 'alice',
          name: 'alice',
          image: 'file://home/me/image.png',
        ).hashCode));
  });

  test('background', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress);
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    expect(await client.background.getVersion(), equals(1));

    var result = await client.background
        .requestBackground(
          parentWindow: 'x11:12345',
          reason: 'Allow your application to run in the background.',
          autostart: true,
          commandLine: ['gedit'],
          dBusActivatable: false,
        )
        .first;
    expect(
        portalServer.background,
        equals([
          MockBackground('x11:12345', {
            'reason':
                DBusString('Allow your application to run in the background.'),
            'autostart': DBusBoolean(true),
            'commandline': DBusArray.string(['gedit']),
            'dbus-activatable': DBusBoolean(false),
          })
        ]));
    expect(
      result,
      equals(
        XdgBackgroundPortalRequestResult(
          background: true,
          autostart: true,
        ),
      ),
    );
    expect(
        result.toString(),
        equals(
            'XdgBackgroundPortalRequestResult(background: true, autostart: true)'));
    expect(
        result.hashCode,
        equals(XdgBackgroundPortalRequestResult(
          background: true,
          autostart: true,
        ).hashCode));
  });

  test('camera access', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress);
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    expect(await client.camera.getVersion(), equals(1));

    await client.camera.accessCamera();
    expect(portalServer.camera, equals([MockCamera({})]));
  });

  test('camera openPipeWire', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress);
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    var result = await client.camera.openPipeWireRemote();
    expect(result, isNotNull);
  });

  test('documents - mount point', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDocumentsServer(clientAddress,
        mountPoint: Uint8List.fromList(utf8.encode('/run/user/1000/doc')));
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    expect(await client.documents.getVersion(), equals(4));

    var mountPoint = await client.documents.getMountPoint();
    expect(mountPoint.path, equals('/run/user/1000/doc'));
  });

  test('documents - add', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDocumentsServer(clientAddress);
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    var dir = await Directory.systemTemp.createTemp('xdg-portal-dart');
    addTearDown(() async {
      await dir.delete(recursive: true);
    });
    var path = '${dir.path}/document';
    var file = File(path);
    // Set the contents to the path we will use in the tests.
    await file.writeAsString('/home/example/image.png');
    var docIds = await client.documents.add([file]);
    expect(
        portalServer.documents,
        equals({
          docIds[0]: MockDocument(
              Uint8List.fromList(utf8.encode('/home/example/image.png')))
        }));
  });

  test('documents - permissions', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDocumentsServer(clientAddress, documents: {
      '123456': MockDocument(
          Uint8List.fromList(utf8.encode('/home/example/image.png')))
    });
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    await client.documents.grantPermissions('123456', 'com.example.App1', {
      XdgDocumentPermission.read,
      XdgDocumentPermission.write,
      XdgDocumentPermission.grantPermissions,
      XdgDocumentPermission.delete
    });
    expect(
        portalServer.documents,
        equals({
          '123456': MockDocument(
              Uint8List.fromList(utf8.encode('/home/example/image.png')),
              permissions: {
                'com.example.App1': {
                  'read',
                  'write',
                  'grant-permissions',
                  'delete'
                }
              })
        }));
    await client.documents.revokePermissions('123456', 'com.example.App1', {
      XdgDocumentPermission.write,
      XdgDocumentPermission.grantPermissions,
      XdgDocumentPermission.delete
    });
    expect(
        portalServer.documents,
        equals({
          '123456': MockDocument(
              Uint8List.fromList(utf8.encode('/home/example/image.png')),
              permissions: {
                'com.example.App1': {'read'}
              })
        }));
  });

  test('documents - delete ', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDocumentsServer(clientAddress, documents: {
      '123456': MockDocument(
          Uint8List.fromList(utf8.encode('/home/example/image.png'))),
      '123457': MockDocument(
          Uint8List.fromList(utf8.encode('/home/example/README.md')))
    });
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    expect(portalServer.documents, hasLength(2));
    await client.documents.delete('123456');
    expect(
        portalServer.documents,
        equals({
          '123457': MockDocument(
              Uint8List.fromList(utf8.encode('/home/example/README.md')))
        }));
  });

  test('email', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress);
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    expect(await client.email.getVersion(), equals(3));

    await client.email.composeEmail(
        parentWindow: 'x11:12345',
        address: 'alice@example.com',
        addresses: ['bob@example.com', 'carol@example.com'],
        cc: ['dave@example.com'],
        bcc: ['elle@example.com'],
        subject: 'Great Opportunity',
        body: 'Would you like to buy some encyclopedias?');
    expect(
        portalServer.composedEmails,
        equals([
          MockEmail('x11:12345', {
            'address': DBusString('alice@example.com'),
            'addresses':
                DBusArray.string(['bob@example.com', 'carol@example.com']),
            'cc': DBusArray.string(['dave@example.com']),
            'bcc': DBusArray.string(['elle@example.com']),
            'subject': DBusString('Great Opportunity'),
            'body': DBusString('Would you like to buy some encyclopedias?')
          })
        ]));
  });

  test('file chooser - open file', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress,
        openFileResponse: MockRequestResponse(0, {
          'uris': DBusArray.string(['file://home/me/image.png'])
        }));
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    expect(await client.fileChooser.getVersion(), equals(1));

    var result = await client.fileChooser.openFile(title: 'Open File').first;
    expect(portalServer.openFileDialogs,
        equals([MockDialog('', 'Open File', {})]));
    expect(result.uris, equals(['file://home/me/image.png']));
    expect(result.choices, isEmpty);
    expect(result.currentFilter, isNull);
  });

  test('file chooser - open file options', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress,
        openFileResponse: MockRequestResponse(0, {
          'uris': DBusArray.string(['file://home/me/image.png']),
          'choices': DBusArray(DBusSignature('(ss)'), [
            DBusStruct([DBusString('color'), DBusString('green')])
          ]),
          'current_filter': DBusStruct([
            DBusString('JPEG Image'),
            DBusArray(DBusSignature('(us)'), [
              DBusStruct([DBusUint32(0), DBusString('*.jpg')]),
              DBusStruct([DBusUint32(1), DBusString('image/jpeg')])
            ])
          ])
        }));
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    var result = await client.fileChooser
        .openFile(
            parentWindow: 'x11:12345',
            title: 'Open File',
            acceptLabel: 'Foo',
            modal: true,
            multiple: true,
            directory: true,
            filters: [
              XdgFileChooserFilter('PNG Image', [
                XdgFileChooserGlobPattern('*.png'),
                XdgFileChooserMimeTypePattern('image/png')
              ])
            ],
            currentFilter: XdgFileChooserFilter(
                'Text Files', [XdgFileChooserGlobPattern('*.txt')]),
            choices: [
              XdgFileChooserChoice(
                  id: 'color',
                  label: 'Color',
                  values: {'red': 'Red', 'green': 'Green', 'blue': 'Blue'},
                  initialSelection: 'green')
            ])
        .first;
    expect(
        portalServer.openFileDialogs,
        equals([
          MockDialog('x11:12345', 'Open File', {
            'accept_label': DBusString('Foo'),
            'modal': DBusBoolean(true),
            'multiple': DBusBoolean(true),
            'directory': DBusBoolean(true),
            'filters': DBusArray(DBusSignature('(sa(us))'), [
              DBusStruct([
                DBusString('PNG Image'),
                DBusArray(DBusSignature('(us)'), [
                  DBusStruct([DBusUint32(0), DBusString('*.png')]),
                  DBusStruct([DBusUint32(1), DBusString('image/png')])
                ])
              ])
            ]),
            'current_filter': DBusStruct([
              DBusString('Text Files'),
              DBusArray(DBusSignature('(us)'), [
                DBusStruct([DBusUint32(0), DBusString('*.txt')])
              ])
            ]),
            'choices': DBusArray(DBusSignature('(ssa(ss)s)'), [
              DBusStruct([
                DBusString('color'),
                DBusString('Color'),
                DBusArray(DBusSignature('(ss)'), [
                  DBusStruct([DBusString('red'), DBusString('Red')]),
                  DBusStruct([DBusString('green'), DBusString('Green')]),
                  DBusStruct([DBusString('blue'), DBusString('Blue')])
                ]),
                DBusString('green')
              ])
            ])
          })
        ]));
    expect(result.uris, equals(['file://home/me/image.png']));
    expect(result.choices, equals({'color': 'green'}));
    expect(
        result.currentFilter,
        equals(XdgFileChooserFilter('JPEG Image', [
          XdgFileChooserGlobPattern('*.jpg'),
          XdgFileChooserMimeTypePattern('image/jpeg')
        ])));

    expect(
        result.currentFilter.toString(),
        equals(
            'XdgFileChooserFilter(JPEG Image, [XdgFileChooserGlobPattern(*.jpg), XdgFileChooserMimeTypePattern(image/jpeg)])'));
    expect(
        result.currentFilter.hashCode,
        equals(XdgFileChooserFilter('JPEG Image', [
          XdgFileChooserGlobPattern('*.jpg'),
          XdgFileChooserMimeTypePattern('image/jpeg')
        ]).hashCode));
  });

  test('file chooser - save file', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress,
        saveFileResponse: MockRequestResponse(0, {
          'uris': DBusArray.string(['file://home/me/image.png'])
        }));
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    var result = await client.fileChooser.saveFile(title: 'Save File').first;
    expect(portalServer.saveFileDialogs,
        equals([MockDialog('', 'Save File', {})]));
    expect(result.uris, equals(['file://home/me/image.png']));
    expect(result.choices, isEmpty);
    expect(result.currentFilter, isNull);
  });

  test('file chooser - save file options', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress,
        saveFileResponse: MockRequestResponse(0, {
          'uris': DBusArray.string(['file://home/me/image.png']),
          'choices': DBusArray(DBusSignature('(ss)'), [
            DBusStruct([DBusString('color'), DBusString('green')])
          ]),
          'current_filter': DBusStruct([
            DBusString('JPEG Image'),
            DBusArray(DBusSignature('(us)'), [
              DBusStruct([DBusUint32(0), DBusString('*.jpg')]),
              DBusStruct([DBusUint32(1), DBusString('image/jpeg')])
            ])
          ])
        }));
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    var result = await client.fileChooser
        .saveFile(
            parentWindow: 'x11:12345',
            title: 'Save File',
            acceptLabel: 'Foo',
            modal: true,
            filters: [
              XdgFileChooserFilter('PNG Image', [
                XdgFileChooserGlobPattern('*.png'),
                XdgFileChooserMimeTypePattern('image/png')
              ])
            ],
            currentFilter: XdgFileChooserFilter(
                'Text Files', [XdgFileChooserGlobPattern('*.txt')]),
            choices: [
              XdgFileChooserChoice(
                  id: 'color',
                  label: 'Color',
                  values: {'red': 'Red', 'green': 'Green', 'blue': 'Blue'},
                  initialSelection: 'green')
            ],
            currentName: 'flutter.png',
            currentFolder: Uint8List.fromList(utf8.encode('/usr/share/icons')),
            currentFile:
                Uint8List.fromList(utf8.encode('/usr/share/icons/dart.png')))
        .first;
    expect(
        portalServer.saveFileDialogs,
        equals([
          MockDialog('x11:12345', 'Save File', {
            'accept_label': DBusString('Foo'),
            'modal': DBusBoolean(true),
            'filters': DBusArray(DBusSignature('(sa(us))'), [
              DBusStruct([
                DBusString('PNG Image'),
                DBusArray(DBusSignature('(us)'), [
                  DBusStruct([DBusUint32(0), DBusString('*.png')]),
                  DBusStruct([DBusUint32(1), DBusString('image/png')])
                ])
              ])
            ]),
            'current_filter': DBusStruct([
              DBusString('Text Files'),
              DBusArray(DBusSignature('(us)'), [
                DBusStruct([DBusUint32(0), DBusString('*.txt')])
              ])
            ]),
            'choices': DBusArray(DBusSignature('(ssa(ss)s)'), [
              DBusStruct([
                DBusString('color'),
                DBusString('Color'),
                DBusArray(DBusSignature('(ss)'), [
                  DBusStruct([DBusString('red'), DBusString('Red')]),
                  DBusStruct([DBusString('green'), DBusString('Green')]),
                  DBusStruct([DBusString('blue'), DBusString('Blue')])
                ]),
                DBusString('green')
              ])
            ]),
            'current_name': DBusString('flutter.png'),
            'current_folder': DBusArray.byte(utf8.encode('/usr/share/icons')),
            'current_file':
                DBusArray.byte(utf8.encode('/usr/share/icons/dart.png')),
          })
        ]));
    expect(result.uris, equals(['file://home/me/image.png']));
    expect(result.choices, equals({'color': 'green'}));
    expect(
        result.currentFilter,
        equals(XdgFileChooserFilter('JPEG Image', [
          XdgFileChooserGlobPattern('*.jpg'),
          XdgFileChooserMimeTypePattern('image/jpeg')
        ])));
  });

  test('file chooser - save files', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress,
        saveFilesResponse: MockRequestResponse(0, {
          'uris': DBusArray.string(['file://home/me/image.png'])
        }));
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    var result = await client.fileChooser.saveFiles(title: 'Save Files').first;
    expect(portalServer.saveFilesDialogs,
        equals([MockDialog('', 'Save Files', {})]));
    expect(result.uris, equals(['file://home/me/image.png']));
    expect(result.choices, isEmpty);
  });

  test('file chooser - save files options', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress,
        saveFilesResponse: MockRequestResponse(0, {
          'uris': DBusArray.string(['file://home/me/image.png']),
          'choices': DBusArray(DBusSignature('(ss)'), [
            DBusStruct([DBusString('color'), DBusString('green')])
          ])
        }));
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    var result = await client.fileChooser
        .saveFiles(
            parentWindow: 'x11:12345',
            title: 'Save Files',
            acceptLabel: 'Foo',
            modal: true,
            choices: [
              XdgFileChooserChoice(
                  id: 'color',
                  label: 'Color',
                  values: {'red': 'Red', 'green': 'Green', 'blue': 'Blue'},
                  initialSelection: 'green')
            ],
            currentFolder: Uint8List.fromList(utf8.encode('/usr/share/icons')),
            files: [
              Uint8List.fromList(utf8.encode('/usr/share/icons/dart.png')),
              Uint8List.fromList(utf8.encode('/usr/share/icons/flutter.png'))
            ])
        .first;
    expect(
        portalServer.saveFilesDialogs,
        equals([
          MockDialog('x11:12345', 'Save Files', {
            'accept_label': DBusString('Foo'),
            'modal': DBusBoolean(true),
            'choices': DBusArray(DBusSignature('(ssa(ss)s)'), [
              DBusStruct([
                DBusString('color'),
                DBusString('Color'),
                DBusArray(DBusSignature('(ss)'), [
                  DBusStruct([DBusString('red'), DBusString('Red')]),
                  DBusStruct([DBusString('green'), DBusString('Green')]),
                  DBusStruct([DBusString('blue'), DBusString('Blue')])
                ]),
                DBusString('green')
              ])
            ]),
            'current_folder': DBusArray.byte(utf8.encode('/usr/share/icons')),
            'files': DBusArray(DBusSignature('ay'), [
              DBusArray.byte(utf8.encode('/usr/share/icons/dart.png')),
              DBusArray.byte(utf8.encode('/usr/share/icons/flutter.png'))
            ])
          })
        ]));
    expect(result.uris, equals(['file://home/me/image.png']));
    expect(result.choices, equals({'color': 'green'}));
  });

  test('file chooser - cancel', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress);
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var busClient = DBusClient(clientAddress);
    var client = XdgDesktopPortalClient(bus: busClient);
    addTearDown(() async {
      await client.close();
    });

    var stream = client.fileChooser.openFile(title: 'Open File');
    var subscription = stream.listen(expectAsync1((result) {}, count: 0));

    // Ensure that the session has been created and then check for it.
    await busClient.ping();
    expect(portalServer.openFileDialogs, hasLength(1));

    // Ensure the dialog is removed when the request is cancelled.
    await subscription.cancel();
    expect(portalServer.openFileDialogs, hasLength(0));
  });

  test('file chooser - cancelled', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress,
        openFileResponse: MockRequestResponse(1, {}));
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var busClient = DBusClient(clientAddress);
    var client = XdgDesktopPortalClient(bus: busClient);
    addTearDown(() async {
      await client.close();
    });

    var stream = client.fileChooser.openFile(title: 'Open File');
    expect(
        () => stream.first, throwsA(isA<XdgPortalRequestCancelledException>()));
  });

  test('file chooser - empty result', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress,
        openFileResponse: MockRequestResponse(0, {}),
        saveFileResponse: MockRequestResponse(0, {}),
        saveFilesResponse: MockRequestResponse(0, {}));
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var busClient = DBusClient(clientAddress);
    var client = XdgDesktopPortalClient(bus: busClient);
    addTearDown(() async {
      await client.close();
    });

    var openFileResult =
        await client.fileChooser.openFile(title: 'Open File').first;
    expect(openFileResult.uris, isEmpty);
    var saveFileResult =
        await client.fileChooser.saveFile(title: 'Save File').first;
    expect(saveFileResult.uris, isEmpty);
    var saveFilesResult =
        await client.fileChooser.saveFiles(title: 'Save Files').first;
    expect(saveFilesResult.uris, isEmpty);
  });

  test('file chooser - failed', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress,
        openFileResponse: MockRequestResponse(2, {}));
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var busClient = DBusClient(clientAddress);
    var client = XdgDesktopPortalClient(bus: busClient);
    addTearDown(() async {
      await client.close();
    });

    var stream = client.fileChooser.openFile(title: 'Open File');
    expect(() => stream.first, throwsA(isA<XdgPortalRequestFailedException>()));
  });

  test('location', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress, locations: [
      <String, DBusValue>{
        'Latitude': DBusDouble(40.9),
        'Longitude': DBusDouble(174.9),
        'Altitude': DBusDouble(42.0),
        'Accuracy': DBusDouble(1.2),
        'Speed': DBusDouble(28),
        'Heading': DBusDouble(321.4),
        'Timestamp': DBusStruct([DBusUint64(1658718568), DBusUint64(0)])
      }
    ]);
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    expect(await client.location.getVersion(), equals(1));

    var locations = client.location.createSession(
        distanceThreshold: 1,
        timeThreshold: 10,
        accuracy: XdgLocationAccuracy.street,
        parentWindow: 'x11:12345');
    locations.listen(expectAsync1((location) {
      expect(
          location,
          equals(XdgLocation(
              latitude: 40.9,
              longitude: 174.9,
              altitude: 42.0,
              accuracy: 1.2,
              speed: 28.0,
              heading: 321.4,
              timestamp:
                  DateTime.fromMicrosecondsSinceEpoch(1658718568000000))));
      expect(
          location.hashCode,
          equals(XdgLocation(
                  latitude: 40.9,
                  longitude: 174.9,
                  altitude: 42.0,
                  accuracy: 1.2,
                  speed: 28.0,
                  heading: 321.4,
                  timestamp:
                      DateTime.fromMicrosecondsSinceEpoch(1658718568000000))
              .hashCode));
      expect(
          location.toString(),
          equals(
              'XdgLocation(latitude: 40.9, longitude: 174.9, altitude: 42.0, accuracy: 1.2, speed: 28.0, heading: 321.4, timestamp: 2022-07-25 03:09:28.000Z)'));
      expect(
          portalServer.locationSessions,
          equals([
            MockLocationSession('x11:12345', {
              'distance-threshold': DBusUint32(1),
              'time-threshold': DBusUint32(10),
              'accuracy': DBusUint32(4)
            })
          ]));
    }));
  });

  test('location - cancel', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress, locations: [
      <String, DBusValue>{
        'Latitude': DBusDouble(40.9),
        'Longitude': DBusDouble(174.9),
        'Altitude': DBusDouble(42.0),
        'Accuracy': DBusDouble(1.2),
        'Speed': DBusDouble(28),
        'Heading': DBusDouble(321.4),
        'Timestamp': DBusStruct([DBusUint64(1658718568), DBusUint64(0)])
      }
    ]);
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var busClient = DBusClient(clientAddress);
    var client = XdgDesktopPortalClient(bus: busClient);
    addTearDown(() async {
      await client.close();
    });

    expect(portalServer.sessions, isEmpty);
    var locations = client.location.createSession(
        distanceThreshold: 1,
        timeThreshold: 10,
        accuracy: XdgLocationAccuracy.street,
        parentWindow: 'x11:12345');
    var locationCompleter = Completer();
    var s = locations.listen((location) async {
      locationCompleter.complete();
    });

    // Ensure that the session has been created and then check for it.
    await busClient.ping();
    expect(portalServer.sessions, hasLength(1));

    /// Once get the first location, cancel the stream which should end the session.
    await locationCompleter.future;
    await s.cancel();
    expect(portalServer.sessions, isEmpty);
  });

  test('location - closed', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress,
        locations: [
          <String, DBusValue>{
            'Latitude': DBusDouble(40.9),
            'Longitude': DBusDouble(174.9),
            'Altitude': DBusDouble(42.0),
            'Accuracy': DBusDouble(1.2),
            'Speed': DBusDouble(28),
            'Heading': DBusDouble(321.4),
            'Timestamp': DBusStruct([DBusUint64(1658718568), DBusUint64(0)])
          },
          <String, DBusValue>{
            'Latitude': DBusDouble(40.9),
            'Longitude': DBusDouble(174.9),
            'Altitude': DBusDouble(45.1),
            'Accuracy': DBusDouble(1.2),
            'Speed': DBusDouble(42),
            'Heading': DBusDouble(302.1),
            'Timestamp': DBusStruct([DBusUint64(1658718569), DBusUint64(0)])
          }
        ],
        closeLocationSession: true);
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var busClient = DBusClient(clientAddress);
    var client = XdgDesktopPortalClient(bus: busClient);
    addTearDown(() async {
      await client.close();
    });

    var locations = client.location.createSession(
        distanceThreshold: 1,
        timeThreshold: 10,
        accuracy: XdgLocationAccuracy.street,
        parentWindow: 'x11:12345');
    expect(
        locations,
        emitsInOrder([
          XdgLocation(
              latitude: 40.9,
              longitude: 174.9,
              altitude: 42.0,
              accuracy: 1.2,
              speed: 28.0,
              heading: 321.4,
              timestamp: DateTime.fromMicrosecondsSinceEpoch(1658718568000000)),
          XdgLocation(
              latitude: 40.9,
              longitude: 174.9,
              altitude: 45.1,
              accuracy: 1.2,
              speed: 42.0,
              heading: 302.1,
              timestamp: DateTime.fromMicrosecondsSinceEpoch(1658718569000000)),
          emitsDone
        ]));
  });

  test('network monitor - status', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress,
        networkAvailable: true, networkMetered: true, networkConnectivity: 0);
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var busClient = DBusClient(clientAddress);
    var client = XdgDesktopPortalClient(bus: busClient);
    addTearDown(() async {
      await client.close();
    });

    expect(await client.networkMonitor.getVersion(), equals(3));

    var n = 0;
    var done = Completer();
    var s = client.networkMonitor.status.listen((status) async {
      if (n == 0) {
        expect(
            status,
            equals(XdgNetworkStatus(
                available: true,
                metered: true,
                connectivity: XdgNetworkConnectivity.local)));

        expect(
            status.toString(),
            equals(
                'XdgNetworkStatus(available: true, metered: true, connectivity: XdgNetworkConnectivity.local)'));
        expect(
            status.hashCode,
            equals(XdgNetworkStatus(
                    available: true,
                    metered: true,
                    connectivity: XdgNetworkConnectivity.local)
                .hashCode));

        await portalServer.setNetworkStatus(
            available: false, metered: false, connectivity: 3);
      } else if (n == 1) {
        expect(
            status,
            equals(XdgNetworkStatus(
                available: false,
                metered: false,
                connectivity: XdgNetworkConnectivity.full)));
        done.complete();
      } else {
        assert(false);
      }
      n++;
    });

    await done.future;
    await s.cancel();
  });

  test('network monitor - can reach', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress);
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    expect(await client.networkMonitor.canReach('example.com', 80), isTrue);
    expect(
        await client.networkMonitor.canReach('unreachable.com', 99), isFalse);
  });

  test('add notification', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress);
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    expect(await client.notification.getVersion(), equals(1));

    await client.notification.addNotification('123',
        title: 'Title',
        body: 'Lorem Ipsum',
        priority: XdgNotificationPriority.high,
        defaultAction: 'action2',
        buttons: [
          XdgNotificationButton(label: 'Button 1', action: 'action1'),
          XdgNotificationButton(label: 'Button 2', action: 'action2')
        ]);
    expect(
        portalServer.notifications,
        equals({
          '123': {
            'title': DBusString('Title'),
            'body': DBusString('Lorem Ipsum'),
            'priority': DBusString('high'),
            'default-action': DBusString('action2'),
            'buttons': DBusArray(DBusSignature('a{sv}'), [
              DBusDict.stringVariant({
                'label': DBusString('Button 1'),
                'action': DBusString('action1')
              }),
              DBusDict.stringVariant({
                'label': DBusString('Button 2'),
                'action': DBusString('action2')
              })
            ])
          }
        }));
  });

  test('add notification - icon file', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress);
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    await client.notification.addNotification('123',
        title: 'Title',
        icon: XdgNotificationIconFile('/usr/share/icons/icon.png'));
    expect(
        portalServer.notifications,
        equals({
          '123': {
            'title': DBusString('Title'),
            'icon': DBusStruct([
              DBusString('file'),
              DBusVariant(DBusString('/usr/share/icons/icon.png'))
            ])
          }
        }));
  });

  test('add notification - icon uri', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress);
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    await client.notification.addNotification('123',
        title: 'Title',
        icon: XdgNotificationIconUri('https://example.com/icon.png'));
    expect(
        portalServer.notifications,
        equals({
          '123': {
            'title': DBusString('Title'),
            'icon': DBusStruct([
              DBusString('file'),
              DBusVariant(DBusString('https://example.com/icon.png'))
            ])
          }
        }));
  });

  test('add notification - icon themed', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress);
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    await client.notification.addNotification('123',
        title: 'Title', icon: XdgNotificationIconThemed(['name', 'fallback']));
    expect(
        portalServer.notifications,
        equals({
          '123': {
            'title': DBusString('Title'),
            'icon': DBusStruct([
              DBusString('themed'),
              DBusVariant(DBusArray.string(['name', 'fallback']))
            ])
          }
        }));
  });

  test('add notification - icon data', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress);
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    await client.notification.addNotification('123',
        title: 'Title',
        icon: XdgNotificationIconData(Uint8List.fromList(
            [0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef])));
    expect(
        portalServer.notifications,
        equals({
          '123': {
            'title': DBusString('Title'),
            'icon': DBusStruct([
              DBusString('bytes'),
              DBusVariant(DBusArray.byte(
                  [0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef]))
            ])
          }
        }));
  });

  test('remove notification', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress,
        notifications: {'122': {}, '123': {}, '124': {}});
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    await client.notification.removeNotification('123');
    expect(portalServer.notifications, equals({'122': {}, '124': {}}));
  });

  test('open uri', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress);
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    expect(await client.openUri.getVersion(), equals(3));

    await client.openUri.openUri('http://example.com',
        parentWindow: 'x11:12345',
        writable: true,
        ask: true,
        activationToken: 'token');
    expect(
        portalServer.openedUris,
        equals([
          MockUri('x11:12345', 'http://example.com', {
            'writable': DBusBoolean(true),
            'ask': DBusBoolean(true),
            'activation_token': DBusString('token')
          })
        ]));
  });

  test('remote desktop', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(
      clientAddress,
      remoteDesktopSessionHandle:
          '/org/freedesktop/portal/desktop/session/456/dart456',
    );
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });
    expect(await client.remoteDesktop.getVersion(), equals(1));
    expect(
        await client.remoteDesktop.getAvailableDeviceTypes(),
        equals(<XdgRemoteDesktopDeviceType>{
          XdgRemoteDesktopDeviceType.pointer,
          XdgRemoteDesktopDeviceType.keyboard,
          XdgRemoteDesktopDeviceType.touchscreen
        }));

    expect(
        await client.remoteDesktop.createSession(
            parentWindow: 'x11:12345',
            deviceTypes: <XdgRemoteDesktopDeviceType>{
              XdgRemoteDesktopDeviceType.pointer,
              XdgRemoteDesktopDeviceType.keyboard
            }),
        equals(<XdgRemoteDesktopDeviceType>{
          XdgRemoteDesktopDeviceType.pointer,
          XdgRemoteDesktopDeviceType.keyboard
        }));

    expect(portalServer.remoteDesktop, [
      MockRemoteDesktop('', {}),
      MockRemoteDesktop('', {'types': DBusUint32(3)}),
      MockRemoteDesktop('x11:12345', {})
    ]);
  });

  test('remote desktop notifiers of pointer', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(
      clientAddress,
      remoteDesktopSessionHandle:
          '/org/freedesktop/portal/desktop/session/456/dart456',
    );
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });
    expect(
        await client.remoteDesktop.createSession(
            parentWindow: 'x11:12345',
            deviceTypes: {XdgRemoteDesktopDeviceType.pointer}),
        equals({XdgRemoteDesktopDeviceType.pointer}));

    await client.remoteDesktop.notifyPointerMotion(dx: 100.1, dy: 200.2);
    expect(
        portalServer.remoteDesktop.last,
        MockRemoteDesktop(
            '', {'dx': DBusDouble(100.1), 'dy': DBusDouble(200.2)}));

    await client.remoteDesktop.notifyPointerButton(
        button: 0x110, state: XdgRemoteDesktopPointerButtonState.pressed);
    expect(
        portalServer.remoteDesktop.last,
        MockRemoteDesktop(
            '', {'button': DBusInt32(0x110), 'state': DBusUint32(1)}));
    await client.remoteDesktop.notifyPointerButton(
        button: 0x110, state: XdgRemoteDesktopPointerButtonState.released);
    expect(
        portalServer.remoteDesktop.last,
        MockRemoteDesktop(
            '', {'button': DBusInt32(0x110), 'state': DBusUint32(0)}));

    await client.remoteDesktop.notifyPointerAxis(dx: 0.0, dy: 20.0);
    expect(portalServer.remoteDesktop.last,
        MockRemoteDesktop('', {'dx': DBusDouble(0), 'dy': DBusDouble(20)}));

    await client.remoteDesktop.notifyPointerAxisDiscrete(
        axis: XdgRemoteDesktopPointerAxisScroll.vertical, steps: -5);
    expect(portalServer.remoteDesktop.last,
        MockRemoteDesktop('', {'axis': DBusUint32(0), 'steps': DBusInt32(-5)}));
  });

  test('remote desktop notifiers of keyboard', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(
      clientAddress,
      remoteDesktopSessionHandle:
          '/org/freedesktop/portal/desktop/session/456/dart456',
    );
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });
    expect(
        await client.remoteDesktop.createSession(
            parentWindow: 'x11:12345',
            deviceTypes: {XdgRemoteDesktopDeviceType.keyboard}),
        equals({XdgRemoteDesktopDeviceType.keyboard}));

    await client.remoteDesktop.notifyKeyboardKeycode(
        keycode: 125, state: XdgRemoteDesktopKeyboardKeyState.pressed);
    expect(
        portalServer.remoteDesktop.last,
        MockRemoteDesktop(
            '', {'keycode': DBusInt32(125), 'state': DBusUint32(1)}));
    await client.remoteDesktop.notifyKeyboardKeycode(
        keycode: 125, state: XdgRemoteDesktopKeyboardKeyState.released);
    expect(
        portalServer.remoteDesktop.last,
        MockRemoteDesktop(
            '', {'keycode': DBusInt32(125), 'state': DBusUint32(0)}));
    await client.remoteDesktop.notifyKeyboardKeysym(
        keysym: 'h'.codeUnitAt(0),
        state: XdgRemoteDesktopKeyboardKeysymState.pressed);
    expect(
        portalServer.remoteDesktop.last,
        MockRemoteDesktop('',
            {'keysym': DBusInt32('h'.codeUnitAt(0)), 'state': DBusUint32(1)}));

    await client.remoteDesktop.notifyKeyboardKeysym(
        keysym: 'h'.codeUnitAt(0),
        state: XdgRemoteDesktopKeyboardKeysymState.released);
    expect(
        portalServer.remoteDesktop.last,
        MockRemoteDesktop('',
            {'keysym': DBusInt32('h'.codeUnitAt(0)), 'state': DBusUint32(0)}));
  });

  test('proxy resolver', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress, proxies: {
      'http://example.com': ['http://localhost:1234']
    });
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    expect(await client.proxyResolver.getVersion(), equals(1));

    expect(await client.proxyResolver.lookup('http://example.com'),
        equals(['http://localhost:1234']));
  });

  test('secret', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    Uint8List secret = Uint8List.fromList(<int>[0, 100, 200, 255]);
    var portalServer = MockPortalDesktopServer(clientAddress, secret: secret);
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    expect(await client.secret.getVersion(), equals(1));
    expect(await client.secret.retrieveSecret(), equals(secret));
  });

  test('settings read', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress, settingsValues: {
      'com.example.test': {'name': DBusString('Fred')}
    });
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    expect(await client.settings.getVersion(), equals(1));

    expect(await client.settings.read('com.example.test', 'name'),
        equals(DBusString('Fred')));
  });

  test('settings read all', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalDesktopServer(clientAddress, settingsValues: {
      'com.example.test1': {
        'name': DBusString('Fred'),
        'age': DBusUint32(42),
        'colour': DBusString('red')
      },
      'com.example.test2': {'name': DBusString('Bob')},
      'com.example.test3': {'name': DBusString('Alice'), 'age': DBusUint32(21)}
    });
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });

    expect(
        await client.settings
            .readAll(['com.example.test1', 'com.example.test3']),
        equals({
          'com.example.test1': {
            'name': DBusString('Fred'),
            'age': DBusUint32(42),
            'colour': DBusString('red')
          },
          'com.example.test3': {
            'name': DBusString('Alice'),
            'age': DBusUint32(21)
          }
        }));
  });
}
