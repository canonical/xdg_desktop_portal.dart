/// Network connectivity states.
enum XdgNetworkConnectivity { local, limited, portal, full }

class XdgNetworkStatus {
  /// true if the network is available.
  bool available;

  /// true if the network is metered.
  bool metered;

  /// The network connectivity state.
  XdgNetworkConnectivity connectivity;

  XdgNetworkStatus(
      {required this.available,
      required this.metered,
      required this.connectivity});

  @override
  int get hashCode => Object.hash(available, metered, connectivity);

  @override
  bool operator ==(other) =>
      other is XdgNetworkStatus &&
      other.available == available &&
      other.metered == metered &&
      other.connectivity == connectivity;

  @override
  String toString() =>
      '$runtimeType(available: $available, metered: $metered, connectivity: $connectivity)';
}
