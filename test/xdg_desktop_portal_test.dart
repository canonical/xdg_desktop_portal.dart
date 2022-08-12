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

class MockDevice {
  final Map<String, DBusValue> options;
  final int pid;
  final List<XdgDeviceType> devices;

  MockDevice(this.pid, this.devices, this.options);

  @override
  int get hashCode => Object.hash(
      pid,
      Object.hashAll(devices.map((entry) => entry.hashCode)),
      Object.hashAll(
          options.entries.map((entry) => Object.hash(entry.key, entry.value))));

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    final mapEquals = const DeepCollectionEquality().equals;

    return other is MockDevice &&
        other.pid == pid &&
        mapEquals(other.devices, devices) &&
        mapEquals(other.options, options);
  }

  @override
  String toString() => '$runtimeType($options)';
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
  final MockPortalServer server;
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
  final MockPortalServer server;

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

class MockPortalObject extends DBusObject {
  final MockPortalServer server;

  MockPortalObject(this.server)
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
      case 'org.freedesktop.portal.Device':
        return handleDeviceMethodCall(methodCall);
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

  Future<DBusMethodResponse> handleDeviceMethodCall(
      DBusMethodCall methodCall) async {
    switch (methodCall.name) {
      case 'AccessDevice':
        var pid = methodCall.values[0].asUint32();
        var devices = methodCall.values[1]
            .asStringArray()
            .map((name) => XdgDeviceType.values.byName(name))
            .toList();
        var options = methodCall.values[2].asStringVariantDict();
        server.device.add(MockDevice(pid, devices, options));
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
      case 'org.freedesktop.portal.Device':
        return getDeviceProperty(name);
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

  Future<DBusMethodResponse> getDeviceProperty(String name) async {
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

  Future<DBusMethodResponse> getSettingsProperty(String name) async {
    switch (name) {
      case 'version':
        return DBusGetPropertyResponse(DBusUint32(1));
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

class MockPortalServer extends DBusClient {
  late final MockPortalObject _root;

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

  final accountDialogs = <MockAccountDialog>[];
  final background = <MockBackground>[];
  final camera = <MockCamera>[];
  final device = <MockDevice>[];
  final composedEmails = <MockEmail>[];
  final openedUris = <MockUri>[];
  final openFileDialogs = <MockDialog>[];
  final saveFileDialogs = <MockDialog>[];
  final saveFilesDialogs = <MockDialog>[];
  Iterable<MockLocationSession> get locationSessions =>
      _locationSessions.values;
  final _locationSessions = <DBusObjectPath, MockLocationSession>{};

  MockPortalServer(DBusAddress clientAddress,
      {this.userId,
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
      this.networkConnectivity = 3})
      : super(clientAddress) {
    _root = MockPortalObject(this);
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

void main() {
  test('account', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalServer(
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

    var portalServer = MockPortalServer(clientAddress);
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

    var portalServer = MockPortalServer(clientAddress);
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

    var portalServer = MockPortalServer(clientAddress);
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

  test('device access', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalServer(clientAddress);
    await portalServer.start();
    addTearDown(() async {
      await portalServer.close();
    });

    var client = XdgDesktopPortalClient(bus: DBusClient(clientAddress));
    addTearDown(() async {
      await client.close();
    });
    expect(await client.device.getVersion(), equals(1));
    final devices = [XdgDeviceType.camera];
    await client.device.accessDevice(pid: pid, devices: devices);
    expect(portalServer.device, equals([MockDevice(pid, devices, {})]));
  });

  test('email', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalServer(clientAddress);
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

    var portalServer = MockPortalServer(clientAddress,
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

    var portalServer = MockPortalServer(clientAddress,
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

    var portalServer = MockPortalServer(clientAddress,
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

    var portalServer = MockPortalServer(clientAddress,
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
            'current_folder': DBusArray.byte([
              47,
              117,
              115,
              114,
              47,
              115,
              104,
              97,
              114,
              101,
              47,
              105,
              99,
              111,
              110,
              115
            ]),
            'current_file': DBusArray.byte([
              47,
              117,
              115,
              114,
              47,
              115,
              104,
              97,
              114,
              101,
              47,
              105,
              99,
              111,
              110,
              115,
              47,
              100,
              97,
              114,
              116,
              46,
              112,
              110,
              103
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
  });

  test('file chooser - save files', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalServer(clientAddress,
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

    var portalServer = MockPortalServer(clientAddress,
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
            'current_folder': DBusArray.byte([
              47,
              117,
              115,
              114,
              47,
              115,
              104,
              97,
              114,
              101,
              47,
              105,
              99,
              111,
              110,
              115
            ]),
            'files': DBusArray(DBusSignature('ay'), [
              DBusArray.byte([
                47,
                117,
                115,
                114,
                47,
                115,
                104,
                97,
                114,
                101,
                47,
                105,
                99,
                111,
                110,
                115,
                47,
                100,
                97,
                114,
                116,
                46,
                112,
                110,
                103
              ]),
              DBusArray.byte([
                47,
                117,
                115,
                114,
                47,
                115,
                104,
                97,
                114,
                101,
                47,
                105,
                99,
                111,
                110,
                115,
                47,
                102,
                108,
                117,
                116,
                116,
                101,
                114,
                46,
                112,
                110,
                103
              ])
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

    var portalServer = MockPortalServer(clientAddress);
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

    var portalServer = MockPortalServer(clientAddress,
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

    var portalServer = MockPortalServer(clientAddress,
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

    var portalServer = MockPortalServer(clientAddress,
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

    var portalServer = MockPortalServer(clientAddress, locations: [
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

    var portalServer = MockPortalServer(clientAddress, locations: [
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

    var portalServer = MockPortalServer(clientAddress,
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

    var portalServer = MockPortalServer(clientAddress,
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

    var portalServer = MockPortalServer(clientAddress);
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

    var portalServer = MockPortalServer(clientAddress);
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

    var portalServer = MockPortalServer(clientAddress);
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

    var portalServer = MockPortalServer(clientAddress);
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

    var portalServer = MockPortalServer(clientAddress);
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

    var portalServer = MockPortalServer(clientAddress);
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

    var portalServer = MockPortalServer(clientAddress,
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

    var portalServer = MockPortalServer(clientAddress);
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

  test('proxy resolver', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalServer(clientAddress, proxies: {
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

  test('settings read', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    addTearDown(() async {
      await server.close();
    });

    var portalServer = MockPortalServer(clientAddress, settingsValues: {
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

    var portalServer = MockPortalServer(clientAddress, settingsValues: {
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
