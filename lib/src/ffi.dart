import "dart:io";
import "dart:ffi";

import "generated/librealsense_ffi_bindings.dart";
export "generated/librealsense_ffi_bindings.dart";

String _getPath() {
  if (Platform.isWindows) {
    return "realsense_ffi.dll";
  } else if (Platform.isMacOS) {
    return "opencv_ffi.dylib";
  } else if (Platform.isLinux) {
    return "realsense_ffi.so";
  } else {
    throw UnsupportedError("Unsupported platform");
  }
}

/// The C bindings generated by `package:ffigen`.
final nativeLib = LibRealSenseBindings(DynamicLibrary.open(_getPath()));