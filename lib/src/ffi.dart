import "dart:io";
import "dart:ffi";

import "generated/librealsense_ffi_bindings.dart";
export "generated/librealsense_ffi_bindings.dart";

String _getPath() {
  if (Platform.isWindows) {
    return "./vcpkg/packages/realsense2_x64-windows/bin/realsense2.dll";
  } else if (Platform.isMacOS) {
    return "opencv_ffi.dylib";
  } else if (Platform.isLinux) {
    return "libopencv_ffi.so";
  } else {
    throw UnsupportedError("Unsupported platform");
  }
}

/// The C bindings generated by `package:ffigen`.
final nativeLib = LibRealSenseBindings(DynamicLibrary.open(_getPath()));
