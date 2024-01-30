import "dart:ffi";

import "package:burt_network/generated.dart";
import "package:burt_network/logging.dart";
import "package:protobuf/protobuf.dart";
import "package:opencv_ffi/opencv_ffi.dart";

import "package:video/video.dart";

class RealSenseIsolate extends CameraIsolate {
  late final RealSenseInterface camera = RealSenseInterface.forPlatform();
  bool hasError = false;
  RealSenseIsolate({required super.details});

  @override
  void initCamera() {
    if (!camera.init()) {
      final details = CameraDetails(status: CameraStatus.CAMERA_DISCONNECTED);
      updateDetails(details);
      return sendLog(LogLevel.warning, "Could not open RealSense");
    }
    sendLog(LogLevel.debug, "RealSense connected");
    final name = camera.getName();
    sendLog(LogLevel.trace, "RealSense model: $name");
    if (!camera.startStream()) {
      final details = CameraDetails(status: CameraStatus.CAMERA_NOT_RESPONDING);
      updateDetails(details);
      return sendLog(LogLevel.warning, "Could not start RealSense");
    }
    sendLog(LogLevel.debug, "Started streaming from RealSense");
  }

  @override
  void disposeCamera() {
    camera.stopStream();
    camera.dispose();
  }

  @override
  void sendFrames() {
    // Get frames from RealSense
    final frames = camera.getFrames();
    if (frames == nullptr) return;

    // Compress colorized frame
    final Pointer<Uint8> rawColorized = frames.ref.colorized_data;
    final Pointer<Mat> colorizedMatrix = getMatrix(camera.height, camera.width, rawColorized);
    final OpenCVImage? colorizedJpg = encodeJpg(colorizedMatrix, quality: details.quality);
    if (colorizedJpg == null) {
      sendLog(LogLevel.debug, "Could not encode colorized frame"); 
    } else {
      sendFrame(colorizedJpg);
    }

    // Compress RGB frame
    final Pointer<Uint8> rawRGB = frames.ref.rgb_data;
    final Pointer<Mat> rgbMatrix = getMatrix(camera.height, camera.width, rawRGB);
    final OpenCVImage? rgbJpg = encodeJpg(rgbMatrix, quality: details.quality);
    if (rgbJpg == null) {
      sendLog(LogLevel.debug, "Could not encode RGB frame"); 
    } else {
      final newDetails = details.deepCopy()..name = CameraName.ROVER_FRONT;
      sendFrame(rgbJpg, detailsOverride: newDetails);
    }

    fpsCount++;
    // send(DepthFramePayload(frames.address));
    nativeLib.Mat_destroy(colorizedMatrix);
    nativeLib.Mat_destroy(rgbMatrix);
    frames.dispose();
  }
}
