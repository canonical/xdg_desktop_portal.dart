import 'dart:async';

import 'package:dbus/dbus.dart';

import '../xdg_desktop_portal_client.dart';
import 'xdg_network_status.dart';

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
      object: client.object,
      interface: 'org.freedesktop.portal.NetworkMonitor',
      name: 'changed',
      signature: DBusSignature(''),
    );
  }

  /// Get network status updates.
  Stream<XdgNetworkStatus> get status {
    var controller = _NetworkStatusStreamController(this);
    return controller.stream;
  }

  /// Returns true if the given [hostname]:[port] is believed to be reachable.
  Future<bool> canReach(String hostname, int port) async {
    var result = await client.callMethod(
      'org.freedesktop.portal.NetworkMonitor',
      'CanReach',
      [DBusString(hostname), DBusUint32(port)],
      replySignature: DBusSignature('b'),
    );
    return result.returnValues[0].asBoolean();
  }

  /// Subscribe or unsubscribe to the changed signal.
  Future<void> _updateChangedSubscription() async {
    if (_activeStatusControllers.isNotEmpty) {
      _changedSubscription ??= _changedSubscription = _changed.listen(
        (signal) async {
          await _updateStatus();
          for (var c in _activeStatusControllers) {
            c.controller.add(_lastStatus!);
          }
        },
      );
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
    var result = await client.callMethod(
      'org.freedesktop.portal.NetworkMonitor',
      'GetStatus',
      [],
      replySignature: DBusSignature('a{sv}'),
    );
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

  Future<void> close() async {
    await _changedSubscription?.cancel();
  }
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
