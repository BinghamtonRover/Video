import "dart:ffi";
import "dart:typed_data";

import "package:burt_network/burt_network.dart";
import "package:protobuf/protobuf.dart";

import "package:video/utils.dart";
import "package:video/realsense.dart";
import "child.dart";

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
  Future<void> sendFrames() async {
    // Get frames from RealSense
    final frames = camera.getFrames();
    if (frames == nullptr) return;

    sendColorizedFrame(frames);
    await sendRgbFrame(frames);

    fpsCount++;
    // send(DepthFramePayload(frames.address));  // For autonomy
    frames.dispose();
  }

  /// Sends the colorized RealSense depth frame
  void sendColorizedFrame(Pointer<NativeFrames> rawFrames) {
    final rawColorized = rawFrames.ref.colorized_data;
    if (rawColorized == nullptr) return;

    final colorizedImage = rawColorized.toOpenCVMat(
      camera.depthResolution,
      length: rawFrames.ref.colorized_length,
    );
    final colorizedJpg = colorizedImage.encodeJpg(quality: details.quality);

    if (colorizedJpg == null) {
      sendLog(LogLevel.debug, "Could not encode colorized frame");
    } else {
      sendFrame(colorizedJpg);
    }

    colorizedImage.dispose();
  }

  /// Sends the RealSense's RGB frame and optionally detects ArUco tags.
  Future<void> sendRgbFrame(Pointer<NativeFrames> rawFrames) async {
    final rawRGB = rawFrames.ref.rgb_data;
    if (rawRGB == nullptr) return;
    final rgbImage = rawRGB.toOpenCVMat(camera.rgbResolution, length: rawFrames.ref.rgb_length);
    await detectAndAnnotateFrames(rgbImage);  // detect ArUco tags

    // Compress the RGB frame into a JPG
    final rgbJpg = rgbImage.encodeJpg(quality: details.quality);
    if (rgbJpg == null) {
      sendLog(LogLevel.debug, "Could not encode RGB frame");
    } else {
      final newDetails = details.deepCopy()..name = CameraName.ROVER_FRONT;
      sendFrame(rgbJpg, detailsOverride: newDetails);
    }

    rgbImage.dispose();
  }

  @override
  Future<Uint8List?> getScreenshotJpeg() async {
    final frames = camera.getFrames();
    if (frames == nullptr) return null;

    final Pointer<Uint8> rgbData = frames.ref.rgb_data;
    if (rgbData == nullptr) return null;
    final rgbImage = rgbData.toOpenCVMat(camera.rgbResolution, length: frames.ref.rgb_length);
    final colorizedJpg = rgbImage.encodeJpg(quality: 100);

    rgbImage.dispose();
    frames.dispose();

    return colorizedJpg;
  }
}
