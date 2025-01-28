import "package:dartcv4/dartcv.dart";
import "package:burt_network/burt_network.dart";
import "package:video/src/isolates/payload.dart";
import "package:video/src/targeting/frame_properties.dart";

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
    frameProperties = FrameProperties.fromFrameDetails(
      captureWidth: camera!.width,
      captureHeight: camera!.height,
      details: details,
    );
    if (!camera!.isOpened) {
      sendLog(LogLevel.warning, "Camera $name is not connected");
      updateDetails(CameraDetails(status: CameraStatus.CAMERA_DISCONNECTED), save: false);
      stop();
    }
  }

  @override
  void disposeCamera() {
    camera?.dispose();
    camera = null;
  }

  @override
  void updateDetails(CameraDetails newDetails, {bool save = true}) {
    super.updateDetails(newDetails, save: save);
    if (details.status != CameraStatus.CAMERA_ENABLED || camera == null) return;
    camera?.setResolution(width: details.resolutionWidth, height: details.resolutionHeight);
    camera?.zoom = details.zoom;
    camera?.pan = details.pan;
    camera?.tilt = details.tilt;
    camera?.focus = details.focus;
    camera?.autofocus = details.focus;
    if (frameProperties == null ||
        newDetails.diagonalFov != frameProperties!.diagonalFoV ||
        frameProperties!.captureWidth != camera!.width ||
        frameProperties!.captureHeight != camera!.height) {
      frameProperties = FrameProperties.fromFrameDetails(
        captureWidth: camera!.width,
        captureHeight: camera!.height,
        details: details,
      );
    }
  }

  @override
  Future<void> sendFrames() async {
    if (camera == null) return;
    final (success, matrix) = camera!.read();
    if (!success) return;

    final detectedMarkers = await detectAndProcessMarkers(details.name, matrix, frameProperties!);
    sendToParent(ObjectDetectionPayload(details: details, tags: detectedMarkers));

    // await matrix.drawCrosshair(center: frameProperties!.center);

    if (details.resolutionWidth != matrix.width ||
        details.resolutionHeight != matrix.height) {
      details.mergeFromMessage(
        CameraDetails(
          resolutionWidth: matrix.width,
          resolutionHeight: matrix.height,
        ),
      );
      saveDetails();
    }

    var streamWidth = matrix.width;
    var streamHeight = matrix.height;
    if (details.hasStreamWidth() && details.streamWidth > 0) {
      streamWidth = details.streamWidth;
    }
    if (details.hasStreamHeight() && details.streamHeight > 0) {
      streamHeight = details.streamHeight;
    }
    if (details.streamWidth != streamWidth ||
        details.streamHeight != streamHeight) {
      updateDetails(CameraDetails(streamWidth: streamWidth, streamHeight: streamHeight));
    }

    final resizedMatrix = Mat.create(cols: streamWidth, rows: streamHeight);

    // No idea why fx and fy are needed, but if they aren't present then sometimes it will crash
    await resizeAsync(
      matrix,
      (streamWidth, streamHeight),
      dst: resizedMatrix,
      fx: streamWidth / matrix.width,
      fy: streamHeight / matrix.height,
    );
    final frame = resizedMatrix.encodeJpg(quality: details.quality);

    resizedMatrix.dispose();
    matrix.dispose();

    if (frame == null) {  // Error getting the frame
      sendLog(LogLevel.warning, "Camera $name didn't respond");
      updateDetails(CameraDetails(status: CameraStatus.CAMERA_NOT_RESPONDING), save: false);
      return;
    }

    sendFrame(frame);
    fpsCount++;
  }
}
