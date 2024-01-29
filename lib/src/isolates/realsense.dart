import "dart:ffi";

import "package:burt_network/generated.dart";
import "package:burt_network/logging.dart";
import "package:opencv_ffi/opencv_ffi.dart";

import "package:video/video.dart";

class RealSenseIsolate extends CameraIsolate {
  late final RealSenseInterface camera = RealSenseInterface.forPlatform();
  bool hasError = false;
  RealSenseIsolate({required super.details});

  void onError(String message) {
    hasError = true;
    sendLog(LogLevel.warning, message);
  }

  @override
  void initCamera() {
    if (!camera.init()) {
      final details = CameraDetails(status: CameraStatus.CAMERA_DISCONNECTED);
      updateDetails(details);
      return onError("Could not open RealSense");
    }
    sendLog(LogLevel.debug, "RealSense connected");
    final name = camera.getName();
    sendLog(LogLevel.trace, "RealSense model: $name");
    if (!camera.startStream()) {
      final details = CameraDetails(status: CameraStatus.CAMERA_NOT_RESPONDING);
      updateDetails(details);
      return onError("Could not start RealSense");
    }
    sendLog(LogLevel.debug, "Started streaming from RealSense");
  }

  @override
  void disposeCamera() {
    camera.stopStream();
    camera.dispose();
  }

  @override
  void sendFrame() {
    // Get frames from RealSense
    final frames = camera.getFrames();
    sendLog(LogLevel.trace, "Got frames: ");
    if (frames.isEmpty) return;
    sendLog(LogLevel.trace, "  Depth: ${frames.ref.depth_data}");
    sendLog(LogLevel.trace, "  Colorized: ${frames.ref.colorized_data}");
    
    // Compress colorized frame
    sendLog(LogLevel.trace, "Encoding JPG...");
    final Pointer<Mat> matrix = getMatrix(camera.height, camera.width, frames.colorizedFrame);
    sendLog(LogLevel.trace, "  Got matrix...");
    final OpenCVImage? jpg = encodeJpg(matrix, quality: 50);
    sendLog(LogLevel.trace, "  Done");
    nativeLib.Mat_destroy(matrix);
    if (jpg == null) return;
    
    send(FramePayload(details: details, address: jpg.pointer.address, length: jpg.data.length));
    // send(DepthFramePayload(frames.address));
    frames.dispose();
  }
}
