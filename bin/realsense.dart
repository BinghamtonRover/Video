import "dart:ffi";

import "package:video/video.dart";
import "package:burt_network/logging.dart";

final logger = BurtLogger();

class RealSense {
  final device = nativeLib.RealSense_create();
  late double scale;
  
  Future<void> init() async {
    nativeLib.RealSense_init(device);
    scale = nativeLib.RealSense_getDepthScale(device);
  }

  Future<void> dispose() async {
    nativeLib.RealSense_free(device);
  }

  Iterable<double> getDepthFrame() sync* { 
    final width = nativeLib.RealSense_getWidth(device);
    final height = nativeLib.RealSense_getHeight(device);
    final frame = nativeLib.RealSense_getDepthFrame(device);
      for (int i = 0; i < width * height; i++){
        yield frame[i] * scale;
      }
  }
}

void main() async {
  final realsense = RealSense();
  await realsense.init();
  logger.info("RealSense initialized");
  final frame = await realsense.getDepthFrame();
  logger.info("Got frame");
  logger.trace(frame.join(", "));  // ignore: cascade_invocations
  await realsense.dispose();
  logger.info("RealSense disposed");
}
