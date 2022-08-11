/// Exception thrown when a portal request fails due to it being cancelled.
class XdgPortalRequestCancelledException implements Exception {
  @override
  String toString() => 'Request was cancelled';
}

/// Exception thrown when a portal request fails.
class XdgPortalRequestFailedException implements Exception {
  @override
  String toString() => 'Request failed';
}
