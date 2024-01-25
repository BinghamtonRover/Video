import "dart:ffi";
import "dart:io";
import "dart:typed_data";

import "../generated/librealsense_ffi_bindings.dart";
export "../generated/librealsense_ffi_bindings.dart";

typedef RealSenseFrame = BurtRsFrame;

extension BurtRsFrameUtils on Pointer<RealSenseFrame> {
  void dispose() {
    if (this == nullptr) return;
    realsenseLib.BurtRsFrame_free(this);
  }

  Uint8List get frame {
    final struct = ref;
    return struct.data.cast<Uint8>().asTypedList(struct.length);
  }
}

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
final realsenseLib = LibRealSenseBindings(DynamicLibrary.open(_getPath()));
