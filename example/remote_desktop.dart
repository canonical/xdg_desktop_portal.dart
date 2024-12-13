import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

void main(List<String> args) async {
  var client = XdgDesktopPortalClient();
  final deviceTypes = await client.remoteDesktop.createSession();
  print(deviceTypes);
  if (deviceTypes.contains(XdgRemoteDesktopDeviceType.pointer)) {
    await notificationsPointer(client);
  }
  if (deviceTypes.contains(XdgRemoteDesktopDeviceType.keyboard)) {
    await notificationsKeyboard(client);
  }
  await client.close();
}

Future<void> notificationsPointer(XdgDesktopPortalClient client) async {
  // 1. Motion.
  await client.remoteDesktop.notifyPointerMotion(dx: 100.0, dy: 100.0);
  await Future.delayed(Duration(seconds: 2));
  // 3. Button.
  int btnLeft = 0x110; // left button
  await client.remoteDesktop.notifyPointerButton(
      button: btnLeft, state: XdgRemoteDesktopPointerButtonState.pressed);
  await client.remoteDesktop.notifyPointerButton(
      button: btnLeft, state: XdgRemoteDesktopPointerButtonState.released);
  await Future.delayed(Duration(seconds: 2));
  // 4. Axis.
  await client.remoteDesktop.notifyPointerAxis(dx: 0.0, dy: 20.0);
  await Future.delayed(Duration(seconds: 2));
  // 5. AxisDiscrete.
  await client.remoteDesktop.notifyPointerAxisDiscrete(
      axis: XdgRemoteDesktopPointerAxisScroll.vertical, steps: -5);
  await Future.delayed(Duration(seconds: 1));
}

Future<void> notificationsKeyboard(XdgDesktopPortalClient client) async {
  // 1. Keycode
  Future<void> clickKeycode(int keyCode) async {
    await client.remoteDesktop.notifyKeyboardKeycode(
        keycode: keyCode, state: XdgRemoteDesktopKeyboardKeyState.pressed);
    await client.remoteDesktop.notifyKeyboardKeycode(
        keycode: keyCode, state: XdgRemoteDesktopKeyboardKeyState.released);
  }

  int keySuper = 125; // key Super (Linux Evdev button codes)
  await clickKeycode(keySuper);
  await Future.delayed(Duration(seconds: 1));
  // 2. Keysym
  Future<void> clickKeysym(int keysym) async {
    await client.remoteDesktop.notifyKeyboardKeysym(
        keysym: keysym, state: XdgRemoteDesktopKeyboardKeysymState.pressed);
    await client.remoteDesktop.notifyKeyboardKeysym(
        keysym: keysym, state: XdgRemoteDesktopKeyboardKeysymState.released);
  }

  final search = 'help';
  for (final codeUnit in search.codeUnits) {
    await clickKeysym(codeUnit);
    await Future.delayed(Duration(milliseconds: 300));
  }
  await Future.delayed(Duration(seconds: 1));
  // Esc
  int keyEsc = 1; //key Esc (Linux Evdev button codes)
  await clickKeycode(keyEsc);
  await clickKeycode(keyEsc);
  await Future.delayed(Duration(seconds: 1));
}
