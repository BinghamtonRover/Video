import "dart:ffi";

import "package:burt_network/burt_network.dart";
import "package:dartcv4/dartcv.dart";
import "package:protobuf/protobuf.dart";
import "package:video/src/targeting/frame_properties.dart";

import "package:video/utils.dart";
import "package:video/video.dart";

extension on CameraDetails {
  bool get interferesWithAutonomy => hasResolutionHeight()
    || hasResolutionWidth()
    || hasFps()
    || hasStatus();
}

/// An isolate to read RGB, depth, and colorized frames from the RealSense.
///
/// While using the RealSense SDK for depth streaming, OpenCV cannot access the standard RGB frames,
/// so it is necessary for this isolate to grab the RGB frames as well.
///
/// Since the RealSense is being used for autonomy, certain settings that could interfere with the
/// autonomy program are not allowed to be changed, even for the RGB camera.
class RealSenseIsolate extends CameraIsolate {
  /// The native RealSense object. MUST be `late` so it isn't initialized on the parent isolate.
  late final RealSenseInterface camera = RealSenseInterface.forPlatform();
  /// Creates an isolate to read from the RealSense camera.
  RealSenseIsolate({required super.details});

  @override
  void onData(VideoCommand data) {
    if (data.details.interferesWithAutonomy) {
      sendLog(LogLevel.error, "That would break autonomy");
    } else {
      super.onData(data);
    }
  }

  @override
  void initCamera() {
    if (!camera.init()) {
      final details = CameraDetails(status: CameraStatus.CAMERA_DISCONNECTED);
      updateDetails(details, save: false);
      return sendLog(LogLevel.warning, "Could not open RealSense");
    }
    sendLog(LogLevel.debug, "RealSense connected");
    final name = camera.getName();
    sendLog(LogLevel.trace, "RealSense model: $name");
    if (!camera.startStream()) {
      final details = CameraDetails(status: CameraStatus.CAMERA_NOT_RESPONDING);
      updateDetails(details, save: false);
      return sendLog(LogLevel.warning, "Could not start RealSense");
    }
    frameProperties = FrameProperties.fromFrameDetails(
      captureWidth: camera.rgbResolution.width,
      captureHeight: camera.rgbResolution.height,
      details: details,
    );
    sendLog(LogLevel.debug, "Started streaming from RealSense");
  }

  @override
  void disposeCamera() {
    camera.stopStream();
    camera.dispose();
  }

  @override
  Future<void> sendFrames() async {
    // Get frames from RealSense
    final frames = camera.getFrames();
    if (frames == nullptr) return;

    // Compress colorized frame
    final Pointer<Uint8> rawColorized = frames.ref.colorized_data;
    if (rawColorized == nullptr) return;
    final colorizedMatrix = rawColorized.toOpenCVMat(camera.depthResolution, length: frames.ref.colorized_length);
    final colorizedJpg = colorizedMatrix.encodeJpg(quality: details.quality);

    if (colorizedJpg == null) {
      sendLog(LogLevel.debug, "Could not encode colorized frame");
    } else {
      sendFrame(colorizedJpg);
    }

    await sendRgbFrame(frames.ref.rgb_data);

    fpsCount++;
    // send(DepthFramePayload(frames.address));  // For autonomy
    colorizedMatrix.dispose();
    frames.dispose();
  }

  /// Sends the RealSense's RGB frame and optionally detects ArUco tags.
  Future<void> sendRgbFrame(Pointer<Uint8> rawRGB) async {
    if (rawRGB == nullptr) return;
    final rgbMatrix = rawRGB.toOpenCVMat(camera.rgbResolution);
    final detectedMarkers = await detectAndProcessMarkers(CameraName.ROVER_FRONT, rgbMatrix, frameProperties!);
    sendToParent(ObjectDetectionPayload(tags: detectedMarkers));

    if (details.resolutionWidth != rgbMatrix.width ||
        details.resolutionHeight != rgbMatrix.height) {
      details.mergeFromMessage(
        CameraDetails(
          resolutionWidth: rgbMatrix.width,
          resolutionHeight: rgbMatrix.height,
        ),
      );
      saveDetails();
    }

    var streamWidth = rgbMatrix.width;
    var streamHeight = rgbMatrix.height;
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

    await resizeAsync(rgbMatrix, (streamWidth, streamHeight), dst: rgbMatrix);

    // Compress the RGB frame into a JPG
    final rgbJpg = rgbMatrix.encodeJpg(quality: details.quality);
    if (rgbJpg == null) {
      sendLog(LogLevel.debug, "Could not encode RGB frame");
    } else {
      final newDetails = details.deepCopy()..name = CameraName.ROVER_FRONT;
      sendFrame(rgbJpg, detailsOverride: newDetails);
    }

    rgbMatrix.dispose();
  }
}
