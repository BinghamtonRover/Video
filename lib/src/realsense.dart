import "dart:ffi";
import "package:ffi/ffi.dart";

import "package:video/video.dart";

typedef RealSenseFrames = ({Pointer<BurtRsFrame> colorized, Pointer<BurtRsFrame> depth});

class RealSense {
  final device = nativeLib.RealSense_create();
  late double scale;
  late int height;
  late int width;
  
  bool init() {
    final status = nativeLib.RealSense_init(device);
    return status == BurtRsStatus.BurtRsStatus_ok;
  }

  String getName() => nativeLib.RealSense_getDeviceName(device).toDartString();

  bool startStream() {
    final status = nativeLib.RealSense_startStream(device);
    if (status != BurtRsStatus.BurtRsStatus_ok) {
      return false;
    }
    final config = nativeLib.RealSense_getDeviceConfig(device);
    height = config.height;
    width = config.width;
    return true;
  }

  void stopStream() => nativeLib.RealSense_stopStream(device);

  Future<void> dispose() async {
    nativeLib.RealSense_free(device);
  }

  RealSenseFrames? getFrames() {
    final depthPointer = nativeLib.RealSense_getDepthFrame(device);
    if (depthPointer == nullptr) return null;
    final colorizedPointer = nativeLib.BurtRsFrame_colorize(depthPointer);
    if (colorizedPointer == nullptr) return null;
    return (depth: depthPointer, colorized: colorizedPointer);
  }
}
