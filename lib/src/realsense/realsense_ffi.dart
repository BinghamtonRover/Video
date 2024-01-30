import "dart:ffi";
import "package:ffi/ffi.dart";

import "package:video/video.dart";

class RealSenseFFI extends RealSenseInterface {
  final device = realsenseLib.RealSense_create();
  @override late double scale;
  @override int height = 0;
  @override int width = 0;
  
  @override
  bool init() {
    final status = realsenseLib.RealSense_init(device);
    return status == BurtRsStatus.BurtRsStatus_ok;
  }

  @override
  String getName() => realsenseLib.RealSense_getDeviceName(device).toDartString();

  @override
  bool startStream() {
    final status = realsenseLib.RealSense_startStream(device);
    if (status != BurtRsStatus.BurtRsStatus_ok) {
      return false;
    }
    final config = realsenseLib.RealSense_getDeviceConfig(device);
    height = config.height;
    width = config.width;
    scale = config.scale;
    print("Resolution: $width x $height");
    return true;
  }

  @override
  void stopStream() => realsenseLib.RealSense_stopStream(device);

  @override
  Future<void> dispose() async {
    realsenseLib.RealSense_free(device);
  }

  @override
  Pointer<NativeFrames> getFrames() => realsenseLib.RealSense_getDepthFrame(device);
}
