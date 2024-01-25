import "dart:ffi";
import "dart:typed_data";
import "dart:io";

import "package:ffi/ffi.dart";
import "package:video/video.dart";
import "package:opencv_ffi/opencv_ffi.dart" as opencv;
import "package:burt_network/logging.dart";
import "package:burt_network/burt_network.dart";


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
    // nativeLib.RealSense_stopStream(device);
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

  Uint8List getColorizedFrame() {
    final framesPtr = nativeLib.RealSense_getFrames(device);
    if (framesPtr == nullptr) {
      logger.warning("No frame returned");
      exit(3);
    }
    final frames = framesPtr.ref;
    final colorized = frames.colorized_frame;
    return colorized.asTypedList(frames.colorized_length);
  }
}

void main() async {
  Logger.level = LogLevel.trace;
  final realsense = RealSense();
  final videoServer = VideoServer(port: 8002);
  await realsense.init();
  await videoServer.init();

  logger.debug("Starting stream");
  await realsense.startStream();

  while (true) {
    logger.debug("Reading frame");
    final frame = realsense.getColorizedFrame();
    logger.info("Got a frame: ${frame.length}");
    final Pointer<opencv.Mat> matrix = opencv.getMatrix(height, width, frame);
    final opencv.OpenCVImage? jpg = opencv.encodeJpg(matrix, quality: 50);
    final details = CameraDetails(name: CameraName.AUTONOMY_DEPTH);
    final message = VideoData(frame: jpg, details: details);
    videoServer.sendMessage(message);
    await Future<void>.delayed(Duration(milliseconds: 100));
  }

  // // await realsense.dispose();
  
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
