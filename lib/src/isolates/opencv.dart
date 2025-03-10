import "package:dartcv4/dartcv.dart";
import "package:burt_network/burt_network.dart";

import "package:video/utils.dart";
import "child.dart";

/// A [CameraIsolate] that reads cameras using `package:opencv_dart`.
class OpenCVCameraIsolate extends CameraIsolate {
  /// The native camera object from OpenCV.
  VideoCapture? camera;

  /// Creates a new manager for the given camera and default details.
  OpenCVCameraIsolate({required super.details});

  @override
  void initCamera() {
    camera = getCamera(name);
    camera?.setResolution(width: details.resolutionWidth, height: details.resolutionHeight);
    if (!camera!.isOpened) {
      sendLog(LogLevel.warning, "Camera $name is not connected");
      updateDetails(CameraDetails(status: CameraStatus.CAMERA_DISCONNECTED));
      stop();
    }
  }

  @override
  void disposeCamera() {
    camera?.dispose();
    camera = null;
  }

  @override
  void updateDetails(CameraDetails newDetails) {
    super.updateDetails(newDetails);
    if (details.status != CameraStatus.CAMERA_ENABLED || camera == null) return;
    camera?.setResolution(width: details.resolutionWidth, height: details.resolutionHeight);
    camera?.zoom = details.zoom;
    camera?.pan = details.pan;
    camera?.tilt = details.tilt;
    camera?.focus = details.focus;
    camera?.autofocus = details.focus;
  }

  @override
  Future<void> sendFrames() async {
    if (camera == null) return;
    final (success, matrix) = camera!.read();
    if (!success) return;
    // detectAndAnnotateFrames(matrix);
    final frame = matrix.encodeJpg(quality: details.quality);
    matrix.dispose();

    if (frame == null) {  // Error getting the frame
      sendLog(LogLevel.warning, "Camera $name didn't respond");
      updateDetails(CameraDetails(status: CameraStatus.CAMERA_NOT_RESPONDING));
      return;
    }

    sendFrame(frame);
    fpsCount++;
  }
}
