import 'dart:io';

import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

// Use `flatpak documents --columns=all` to show current documents

void usage() {
  print('Usage:');
  print('documents get-mount-point');
  print('documents add <path>');
  print('documents grant-permissions <doc-id> <app-id> <permissions>');
  print('documents revoke-permissions <doc-id> <app-id> <permissions>');
  print('documents delete <doc-id>');
}

void main(List<String> args) async {
  if (args.isEmpty) {
    usage();
    return;
  }
  var command = args[0];

  var client = XdgDesktopPortalClient();

  switch (command) {
    case 'get-mount-point':
      var mountPoint = await client.documents.getMountPoint();
      print(mountPoint.path);
      break;
    case 'add':
      if (args.length < 2) {
        usage();
      } else {
        var path = args[1];
        var docId = await client.documents.add([File(path)]);
        print(docId[0]);
      }
      break;
    case 'grant-permissions':
      if (args.length < 4) {
        usage();
      } else {
        var docId = args[1];
        var appId = args[2];
        var permissions = parsePermissions(args.sublist(3));
        if (permissions != null) {
          await client.documents.grantPermissions(docId, appId, permissions);
        }
      }
      break;
    case 'revoke-permissions':
      if (args.length < 4) {
        usage();
      } else {
        var docId = args[1];
        var appId = args[2];
        var permissions = parsePermissions(args.sublist(3));
        if (permissions != null) {
          await client.documents.revokePermissions(docId, appId, permissions);
        }
      }
      break;
    case 'delete':
      if (args.length < 2) {
        usage();
      } else {
        var docId = args[1];
        await client.documents.delete(docId);
      }
      break;
    default:
      usage();
      break;
  }

  await client.close();
}

Set<XdgDocumentPermission>? parsePermissions(Iterable<String> permissionNames) {
  var permissions = <XdgDocumentPermission>{};
  for (var name in permissionNames) {
    var permission = {
      'read': XdgDocumentPermission.read,
      'write': XdgDocumentPermission.write,
      'grant-permissions': XdgDocumentPermission.grantPermissions,
      'delete': XdgDocumentPermission.delete
    }[name];
    if (permission == null) {
      print("Unknown permission '$name'");
      usage();
      return null;
    }
    permissions.add(permission);
  }
  return permissions;
}
