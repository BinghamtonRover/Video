import "dart:ffi";

import "package:burt_network/generated.dart";
import "package:burt_network/logging.dart";

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
    if (hasError) return;
    final depthPointer = camera.getDepthFrame();
    sendLog(LogLevel.trace, "Got depth frame: $depthPointer");
    // if (depthPointer.isEmpty) return updateDetails(CameraDetails(status: CameraStatus.CAMERA_NOT_RESPONDING));
    if (depthPointer.isEmpty) return;
    final colorized = camera.colorize(depthPointer, quality: 50);
    sendLog(LogLevel.trace, "Got colorized frame: $colorized");
    if (colorized == null) return updateDetails(CameraDetails(status: CameraStatus.CAMERA_NOT_RESPONDING));
    send(FramePayload(details: details, address: colorized.pointer.address, length: colorized.data.length));
    send(DepthFramePayload(depthPointer.address));
  }
}
