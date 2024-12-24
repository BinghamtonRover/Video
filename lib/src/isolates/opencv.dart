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
  /// Frame properties used for target tracking calculations
  FrameProperties? frameProperties;
  /// Creates a new manager for the given camera and default details.
  OpenCVCameraIsolate({required super.details});

  @override
  void initCamera() {
    camera = getCamera(name);
    camera?.setResolution(width: details.resolutionWidth, height: details.resolutionHeight);
    frameProperties = FrameProperties(
      captureWidth: camera!.width,
      captureHeight: camera!.height,
      diagonalFoV: details.fov,
    );
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
    if (frameProperties == null ||
        newDetails.fov != frameProperties!.diagonalFoV ||
        frameProperties!.captureWidth != camera!.width ||
        frameProperties!.captureHeight != camera!.height) {
      frameProperties = FrameProperties(
        captureWidth: camera!.width,
        captureHeight: camera!.height,
        diagonalFoV: newDetails.fov,
      );
    }
  }

  @override
  Future<void> sendFrames() async {
    if (camera == null) return;
    final (success, matrix) = camera!.read();
    if (!success) return;
    final (corners, ids, rejected) = await detectArucoMarkers(matrix);
    final detectedMarkers = <TrackedTarget>[];
    for (int i = 0; i < ids.length; i++) {
      var centerX = 0.0;
      var centerY = 0.0;
      for (final corner in corners[i]) {
        centerX += corner.x;
        centerY += corner.y;
      }
      centerX /= 4;
      centerY /= 4;

      final (:yaw, :pitch) = calculateYawPitch(frameProperties!, centerX, centerY);

      final cornerVec = VecPoint.generate(
          corners[i].length,
          (idx) => Point(corners[i][idx].x.toInt(), corners[i][idx].y.toInt()),
        );
      final area = contourArea(cornerVec);

      cornerVec.dispose();

      detectedMarkers.add(
        TrackedTarget(
          detectionType: TargetDetectionType.ARUCO,
          tagId: ids[i],
          yaw: yaw,
          pitch: pitch,
          area: area,
          areaPercent: area / (matrix.width * matrix.height),
          centerX: centerX.toInt(),
          centerY: centerY.toInt(),
          corners: corners[i].expand((corner) sync* {
            yield corner.x.toInt();
            yield corner.y.toInt();
          }),
        ),
      );
    }
    sendToParent(ArucoDetectionPayload(camera: name, tags: detectedMarkers));
    var streamWidth = matrix.width;
    var streamHeight = matrix.height;
    if (details.hasStreamWidth()) {
      streamWidth = details.streamWidth;
    }

    if (details.hasStreamHeight()) {
      streamHeight = details.streamHeight;
    }
    await resizeAsync(matrix, (streamWidth, streamHeight), dst: matrix);
    final frame = matrix.encodeJpg(quality: details.quality);

    matrix.dispose();
    corners.dispose();
    ids.dispose();
    rejected.dispose();

    if (frame == null) {  // Error getting the frame
      sendLog(LogLevel.warning, "Camera $name didn't respond");
      updateDetails(CameraDetails(status: CameraStatus.CAMERA_NOT_RESPONDING));
      return;
    }

    sendFrame(frame);
    fpsCount++;
  }
}
