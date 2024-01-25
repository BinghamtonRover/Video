import "dart:ffi";
import "dart:io";

import "package:ffi/ffi.dart";
import "package:video/video.dart";
import "package:burt_network/logging.dart";

final logger = BurtLogger();

class RealSense {
  final device = nativeLib.RealSense_create();
  late double scale;
  
  Future<void> init() async {
    final status = nativeLib.RealSense_init(device);
    if (status != BurtRsStatus.BurtRsStatus_ok) {
      logger.warning("Initialization failed!");
      exit(1);
    }
    final name = nativeLib.RealSense_getDeviceName(device);
    final nameString = name.toDartString();
    logger.info("RealSense initialized");
    logger.trace("Device: $nameString");
  }

  Future<void> startStream() async {
    final status = nativeLib.RealSense_startStream(device);
    if (status != BurtRsStatus.BurtRsStatus_ok) {
      logger.warning("Stream failed!");
      exit(2);
    }
    logger.info("Stream started");
  }

  Future<void> dispose() async {
    nativeLib.RealSense_stopStream(device);
    nativeLib.RealSense_free(device);
    logger.info("Disposed of RealSense device");
  }

  // Iterable<double> getDepthFrame() sync* { 
  //   final width = nativeLib.RealSense_getWidth(device);
  //   final height = nativeLib.RealSense_getHeight(device);
  //   final frame = nativeLib.RealSense_getDepthFrame(device);
  //     for (int i = 0; i < width * height; i++){
  //       yield frame[i] * scale;
  //     }
  // }
}

void main() async {
  Logger.level = LogLevel.trace;
  final realsense = RealSense();
  await realsense.init();
  await realsense.dispose();
  
  // print("Getting depth");
  // final frameGenerator = realsense.getDepthFrame();
  // final frame = <double>[];
  // for(final value in frameGenerator){
  //   frame.add(value);
  // }
  // logger.info("Got frame");
  // logger.trace(frame.join(", "));  // ignore: cascade_invocations
  // await realsense.dispose();
  // logger.info("RealSense disposed");
}
