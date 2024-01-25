import "package:burt_network/generated.dart";
import "package:burt_network/logging.dart";
import "package:video/video.dart";

class RealSenseIsolate extends CameraIsolate {
  late final RealSense camera = RealSense();
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
    final frames = camera.getFrames();
    if (frames == null) return updateDetails(CameraDetails(status: CameraStatus.CAMERA_NOT_RESPONDING));
    send(FramePayload(details: details, address: frames.colorized.address, length: frames.colorized.length));
    send(DepthFramePayload(frames.depth));
  }
}
