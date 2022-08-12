import 'package:dbus/dbus.dart';

import 'xdg_portal_request.dart';

/// Information about a user account.
class XdgAccountUserInformation {
  /// The user id.
  final String id;

  /// The users real name.
  final String name;

  /// The URI of an image file for the users avatar photo.
  final String image;

  XdgAccountUserInformation(
      {required this.id, required this.name, required this.image});

  @override
  int get hashCode => Object.hash(id, name, image);

  @override
  bool operator ==(other) =>
      other is XdgAccountUserInformation &&
      other.id == id &&
      other.name == name &&
      other.image == image;

  @override
  String toString() => '$runtimeType(id: $id, name: $name, image: $image)';
}

/// Portal for obtaining information about the user.
class XdgAccountPortal {
  final DBusRemoteObject _object;
  final String Function() _generateToken;

  XdgAccountPortal(this._object, this._generateToken);

  /// Get the version of this portal.
  Future<int> getVersion() => _object
      .getProperty('org.freedesktop.portal.Account', 'version',
          signature: DBusSignature('u'))
      .then((v) => v.asUint32());

  /// Gets information about the user.
  Stream<XdgAccountUserInformation> getUserInformation(
      {String parentWindow = '', String? reason}) {
    var request = XdgPortalRequest(
      _object,
      () async {
        var options = <String, DBusValue>{};
        options['handle_token'] = DBusString(_generateToken());
        if (reason != null) {
          options['reason'] = DBusString(reason);
        }
        var result = await _object.callMethod(
            'org.freedesktop.portal.Account',
            'GetUserInformation',
            [DBusString(parentWindow), DBusDict.stringVariant(options)],
            replySignature: DBusSignature('o'));
        return result.returnValues[0].asObjectPath();
      },
    );
    return request.stream.map(
      (result) => XdgAccountUserInformation(
        id: result['id']?.asString() ?? '',
        name: result['name']?.asString() ?? '',
        image: result['image']?.asString() ?? '',
      ),
    );
  }
}
