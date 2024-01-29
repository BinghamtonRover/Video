import "package:opencv_ffi/opencv_ffi.dart";
import "package:burt_network/burt_network.dart";
import "package:burt_network/logging.dart";

import "package:video/video.dart";

/// An isolate that is spawned to manage one camera.
/// 
/// This class accepts [VideoCommand]s and calls [updateDetails] with the newly-received details.
/// When a frame is read, instead of sending the [VideoData], this class sends only the pointer
/// to the [OpenCVImage] via the [IsolatePayload] class, and the image is read by the parent isolate.
class OpenCVCameraIsolate extends CameraIsolate {
  /// The native camera object from OpenCV.
  late final Camera camera;
  /// Creates a new manager for the given camera and default details.
  OpenCVCameraIsolate({required super.details}); 

  @override
  void initCamera() {
    camera = getCamera(name);
    if (!camera.isOpened) {
      sendLog(LogLevel.warning, "Camera $name is not connected");
      updateDetails(CameraDetails(status: CameraStatus.CAMERA_DISCONNECTED));
    }
  }

  @override
  void disposeCamera() => camera.dispose();

  /// Reads a frame from the camera and sends it to the dashboard.
  /// 
  /// Checks for multiple errors along the way: 
  /// - If the camera does not respond, alerts the dashboard
  /// - If the frame is too large, reduces the quality (increases JPG compression)
  /// - If the quality is already low, alerts the dashboard
  @override
  void sendFrame() {
    final frame = camera.getJpg(quality: details.quality);
    if (frame == null) {  // Error getting the frame
      sendLog(LogLevel.warning, "Camera $name didn't respond");
      updateDetails(CameraDetails(status: CameraStatus.CAMERA_NOT_RESPONDING));
    } else if (frame.data.length < 60000) {  // Frame can be sent
      send(FramePayload(address: frame.pointer.address, length: frame.data.length, details: details));
      fpsCount++;
    } else if (details.quality > 25) {  // Frame too large, try lowering quality
      sendLog(LogLevel.debug, "Lowering quality for $name from ${details.quality}");
      updateDetails(CameraDetails(quality: details.quality - 1));
    } else {  // Frame too large, cannot lower quality anymore
      sendLog(LogLevel.warning, "$name's frames are too large (${frame.data.length} bytes, quality=${details.quality})");
      updateDetails(CameraDetails(status: CameraStatus.FRAME_TOO_LARGE));
    }
  }
}