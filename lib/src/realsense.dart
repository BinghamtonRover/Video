import "dart:ffi";
import "package:ffi/ffi.dart";

import "package:video/video.dart";

typedef RealSenseFrame = ({int address, int length, int rsAddress});
typedef RealSenseFrames = ({RealSenseFrame colorized, RealSenseFrame depth});

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
    final depthPtr = nativeLib.RealSense_getDepthFrame(device);
    if (depthPtr == nullptr) return null;
    final depthResult = depthPtr.ref;
    final colorPtr = nativeLib.BurtRsFrame_colorize(depthPtr);
    if (colorPtr == nullptr) return null;
    final colorResult = colorPtr.ref;
    return (
      depth: (address: depthResult.data.address, length: depthResult.length, rsAddress: depthPtr.address), 
      colorized: (address: colorResult.data.address, length: colorResult.length, rsAddress: colorPtr.address),
    );
  }
}
