import "dart:ffi";

import "package:burt_network/generated.dart";
import "package:burt_network/logging.dart";
import "package:protobuf/protobuf.dart";
import "package:opencv_ffi/opencv_ffi.dart";
import "package:video/src/lidar/lidar.dart";

import "package:video/video.dart";


class LidarIsolate extends CameraIsolate {
  /// The native RealSense object. MUST be `late` so it isn't initialized on the parent isolate.
  late final LidarFFI camera = LidarFFI();
  /// Creates an isolate to read from the Lidar.
  LidarIsolate({required super.details});

  @override
  Future<void> initCamera() async {
    if (!await camera.init()) {
      final details = CameraDetails(status: CameraStatus.CAMERA_DISCONNECTED);
      updateDetails(details);
      return sendLog(LogLevel.warning, "Could not open Lidar");
    }
    final details = CameraDetails(status: CameraStatus.CAMERA_ENABLED);
    updateDetails(details);
    sendLog(LogLevel.warning, "Lidar connected");
  }

  @override
  void disposeCamera() {
    camera.dispose();
  }

  @override
  void sendFrames() async{
    // Get frames from Lidar
    final frame = await camera.getOneImage(timeout: 1);
    if (frame == null) {
      logger.warning("Null image");
      return;
    }
    logger.info("Got frame");

    // Compress colorized frame
    sendFrame(frame);
    logger.info("Here2");
    // frame.dispose();
    //await Future<void>.delayed(const Duration(seconds:8));
  }
}
