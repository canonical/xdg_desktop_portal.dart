import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void main() async {
  var client = XdgDesktopPortalClient();

  var value =
      await client.settings.read('org.gnome.desktop.interface', 'font-name');
  var fontName = value.asVariant().asString();
  print('Font set to $fontName');

  await client.close();
}
