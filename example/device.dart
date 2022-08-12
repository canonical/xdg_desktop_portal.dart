import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';
import 'dart:io';

void main(List<String> args) async {
  var client = XdgDesktopPortalClient();
  await client.device.accessDevice(
    pid: pid,
    devices: [XdgDeviceType.camera],
  );
  await client.close();
}
