import 'dart:io';
import 'dart:typed_data';

import 'package:dbus/dbus.dart';

/// Permissions that can be assigned to documents.
enum XdgDocumentPermission { read, write, grantPermissions, delete }

final _permissionToString = {
  XdgDocumentPermission.read: 'read',
  XdgDocumentPermission.write: 'write',
  XdgDocumentPermission.grantPermissions: 'grant-permissions',
  XdgDocumentPermission.delete: 'delete'
};

/// Portal to access documents.
class XdgDocumentsPortal {
  final DBusRemoteObject _object;

  XdgDocumentsPortal(this._object);

  /// Get the version of this portal.
  Future<int> getVersion() => _object
      .getProperty('org.freedesktop.portal.Documents', 'version',
          signature: DBusSignature('u'))
      .then((v) => v.asUint32());

  /// Returns the path at which the document store fuse filesystem is mounted. This will typically be `/run/user/$UID/doc/`.
  Future<Directory> getMountPoint() async {
    var result = await _object.callMethod(
        'org.freedesktop.portal.Documents', 'GetMountPoint', [],
        replySignature: DBusSignature('ay'));
    return Directory.fromRawPath(
        Uint8List.fromList(result.values[0].asByteArray().toList()));
  }

  /// Adds files to the document store.
  /// Returns the document IDs for these document.
  Future<List<String>> add(Iterable<File> files,
      {bool reuseExisting = false,
      bool persistent = false,
      bool asNeededByApp = false,
      bool exportDirectory = false,
      String appId = '',
      Set<XdgDocumentPermission> permissions = const {}}) async {
    var openedFiles = <RandomAccessFile>[];
    for (var file in files) {
      openedFiles.add(await file.open());
    }
    var flags = 0;
    if (reuseExisting) {
      flags |= 0x1;
    }
    if (persistent) {
      flags |= 0x2;
    }
    if (asNeededByApp) {
      flags |= 0x4;
    }
    if (exportDirectory) {
      flags |= 0x8;
    }
    var result = await _object.callMethod(
        'org.freedesktop.portal.Documents',
        'AddFull',
        [
          DBusArray.unixFd(openedFiles.map((f) => ResourceHandle.fromFile(f))),
          DBusUint32(flags),
          DBusString(appId),
          DBusArray.string(permissions.map((p) => _permissionToString[p] ?? ''))
        ],
        replySignature: DBusSignature('asa{sv}'));
    for (var f in openedFiles) {
      await f.close();
    }
    return result.returnValues[0].asStringArray().toList();
  }

  /// Grants access permissions for a file with [docId] to the application with [appId].
  Future<void> grantPermissions(String docId, String appId,
      Set<XdgDocumentPermission> permissions) async {
    await _object.callMethod(
        'org.freedesktop.portal.Documents',
        'GrantPermissions',
        [
          DBusString(docId),
          DBusString(appId),
          DBusArray.string(permissions.map((p) => _permissionToString[p] ?? ''))
        ],
        replySignature: DBusSignature(''));
  }

  /// Revokes access permissions for a file with [docId] from the application with [appId].
  Future<void> revokePermissions(String docId, String appId,
      Set<XdgDocumentPermission> permissions) async {
    await _object.callMethod(
        'org.freedesktop.portal.Documents',
        'RevokePermissions',
        [
          DBusString(docId),
          DBusString(appId),
          DBusArray.string(permissions.map((p) => _permissionToString[p] ?? ''))
        ],
        replySignature: DBusSignature(''));
  }

  /// Removes an entry from the document store. The file itself is not deleted.
  Future<void> delete(String docId) async {
    await _object.callMethod(
        'org.freedesktop.portal.Documents', 'Delete', [DBusString(docId)],
        replySignature: DBusSignature(''));
  }
}
