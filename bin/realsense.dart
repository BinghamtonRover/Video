import "dart:ffi";
import "dart:io";

import "package:video/video.dart";
import "package:opencv_ffi/opencv_ffi.dart" as opencv;
import "package:burt_network/logging.dart";
import "package:burt_network/burt_network.dart";


final logger = BurtLogger();

void main() async {
  Logger.level = LogLevel.trace;
  late final RealSense realsense = RealSense();
  final videoServer = VideoServer(port: 8002);
  await videoServer.init();

  logger.info("Opening camera");
  if (!realsense.init()) {
    logger.critical("Could not open the RealSense");
    exit(1);
  } 
  logger.info("Starting stream");
  if (!realsense.startStream()) {
    logger.critical("Could not start RealSense stream");
  }

  while (true) {
    logger.debug("Reading frame");
    final frames = realsense.getFrames();
    if (frames == null) {
      logger.warning("No frame"); 
      continue;
    }
    // Don't need the depth data, just the colorized version
    nativeLib.BurtRsFrame_free(Pointer.fromAddress(frames.depth.address));
    final colorPointer = Pointer<Uint8>.fromAddress(frames.colorized.address);
    final colorFrame = colorPointer.asTypedList(frames.colorized.length);
    final Pointer<opencv.Mat> matrix = opencv.getMatrix(realsense.height, realsense.width, colorFrame);
    logger.trace("Matrix pointer: $matrix");
    final opencv.OpenCVImage? jpg = opencv.encodeJpg(matrix, quality: 50);
    if (jpg == null) {
      logger.warning("Could not encode matrix: $matrix");
      exit(4);
    }
    final bytes = jpg.data;
    final details = CameraDetails(status: CameraStatus.CAMERA_ENABLED, name: CameraName.AUTONOMY_DEPTH);
    final message = VideoData(frame: bytes, details: details);
    videoServer.sendMessage(message);
    await Future<void>.delayed(const Duration(milliseconds: 100));
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
