import 'dart:ffi' as ffi;

typedef BoolInC = ffi.Bool Function();
typedef BoolDartFunc = bool Function();

class XdgPortal {
  final libPortalLib = ffi.DynamicLibrary.open('libportal.so.1');

  bool runningUnderSnap() {
    final BoolDartFunc runningUnderSnap = libPortalLib
        .lookup<ffi.NativeFunction<BoolInC>>('xdp_portal_running_under_snap')
        .asFunction();
    return runningUnderSnap();
  }

  bool runningUnderSandbox() {
    final BoolDartFunc runningUnderSandbox = libPortalLib
        .lookup<ffi.NativeFunction<BoolInC>>('xdp_portal_running_under_sandbox')
        .asFunction();
    return runningUnderSandbox();
  }

  bool runningUnderFlatpak() {
    final BoolDartFunc runningUnderFlatpak = libPortalLib
        .lookup<ffi.NativeFunction<BoolInC>>('xdp_portal_running_under_flatpak')
        .asFunction();
    return runningUnderFlatpak();
  }
}
