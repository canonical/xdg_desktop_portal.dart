import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void main(List<String> args) async {
  var client = XdgDesktopPortalClient();
  final reason =
      'Allows your personal information to be included with recipes you share with your friends.';
  var userInformation =
      await client.account.getUserInformation(reason: reason).first;
  print('$userInformation');

  await client.close();
}
