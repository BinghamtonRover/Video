import "dart:typed_data";

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
    if (details.hasFps()) camera?.fps = details.fps;
    if (details.hasZoom()) camera?.zoom = details.zoom;
    if (details.hasFocus()) camera?.focus = details.focus;
    camera?.autofocus = details.autofocus;

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
    camera?.autofocus = details.autofocus;
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

  @override
  Future<Uint8List?> getScreenshotJpeg() async {
    if (camera == null) {
      return null;
    }
    final originalWidth = camera!.get(CAP_PROP_FRAME_WIDTH).toInt();
    final originalHeight = camera!.get(CAP_PROP_FRAME_HEIGHT).toInt();

    final originalFps = camera!.fps;

    final originalExposure = camera!.get(CAP_PROP_EXPOSURE);
    final originalAutoExposure = camera!.get(CAP_PROP_AUTO_EXPOSURE);

    final originalWbTemp = camera!.get(CAP_PROP_WB_TEMPERATURE);
    final originalAutoWb = camera!.get(CAP_PROP_AUTO_WB);

    camera!.setResolution(width: 10000, height: 10000);

    camera!.fps = 0;
    if (details.hasZoom()) camera!.zoom = details.zoom;
    if (details.hasFocus()) camera!.focus = details.focus;
    camera!.autofocus = details.autofocus;

    camera!.set(CAP_PROP_AUTO_EXPOSURE, 3);
    camera!.set(CAP_PROP_EXPOSURE, originalExposure);

    camera!.set(CAP_PROP_AUTO_WB, 1);
    camera!.set(CAP_PROP_WB_TEMPERATURE, originalWbTemp);

    for (int i = 0; i < 3; i++) {
      camera!.grab();
    }

    final (success, matrix) = await camera!.readAsync();

    camera!.setResolution(width: originalWidth, height: originalHeight);
    camera!.fps = originalFps;
    if (details.hasZoom()) camera!.zoom = details.zoom;
    if (details.hasFocus()) camera!.focus = details.focus;
    camera!.autofocus = details.autofocus;
    camera!.set(CAP_PROP_AUTO_EXPOSURE, originalAutoExposure);
    camera!.set(CAP_PROP_AUTO_WB, originalAutoWb);

    if (!success) return null;

    final frame = matrix.encodeJpg(quality: 100);
    matrix.dispose();

    return frame;
  }
}
