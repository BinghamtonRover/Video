import "dart:ffi";
import "package:ffi/ffi.dart";
import "package:opencv_ffi/opencv_ffi.dart";

import "package:video/video.dart";

class RealSenseFFI extends RealSenseInterface {
  final device = realsenseLib.RealSense_create();
  late double scale;
  late int _height;
  late int _width;
  
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
    _height = config.height;
    _width = config.width;
    return true;
  }

  @override
  void stopStream() => realsenseLib.RealSense_stopStream(device);

  @override
  Future<void> dispose() async {
    realsenseLib.RealSense_free(device);
  }

  @override
  Pointer<RealSenseFrame> getDepthFrame() {
    final depthPointer = realsenseLib.RealSense_getDepthFrame(device);
    return depthPointer;
  }

  @override
  OpenCVImage? colorize(Pointer<RealSenseFrame> depthFrame, {int quality = 75}) { 
    final colorizedPointer = realsenseLib.BurtRsFrame_colorize(depthFrame);
    if (colorizedPointer == nullptr) return null;
    final image = getMatrix(_height, _width, colorizedPointer.frame);
    final jpg = encodeJpg(image, quality: quality);
    return jpg;
  }
}
