import "dart:ffi";
import "dart:io";

import "package:video/video.dart";
import "package:burt_network/logging.dart";

final logger = BurtLogger();

class RealSense {
  final device = nativeLib.RealSense_create();
  late double scale;
  
  Future<void> init() async {
    print("Initializing...");
    final status = nativeLib.RealSense_init(device);
    if (status != BurtRsStatus.BurtRsStatus_ok) {
      logger.warning("Initialization failed!");
      exit(1);
    }
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
  return;
  print("Getting depth");
  final frameGenerator = realsense.getDepthFrame();
  final frame = <double>[];
  for(final value in frameGenerator){
    frame.add(value);
  }
  logger.info("Got frame");
  logger.trace(frame.join(", "));  // ignore: cascade_invocations
  await realsense.dispose();
  logger.info("RealSense disposed");
}
