import "dart:ffi";

import "package:burt_network/generated.dart";
import "package:burt_network/logging.dart";
import "package:protobuf/protobuf.dart";
import "package:opencv_ffi/opencv_ffi.dart";

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

  List<List<double>> compressDepthFrame(Pointer<Uint8> depthFrame, int newHeight, int newWidth){
    /*
    depthFrame is a 1D array with length camera.height * camera.width
    depthFrame[row*camera.width + column] = matrix[row]][column] 
    1. Turn DepthFrame to 2D Matrix
    2. break it up into a gride of newWidth * newHeight
    Each box will be (camera.height / newHeight) * (camera.width / newWidth)
    */
    int sum = 0; 
    final matrix = <List<double>>[];
    final size = (camera.height / newHeight) * (camera.width / newWidth);
    int currRow = 0;
    int currColumn = 0;
    for(int row = 0; row < camera.width / newWidth; row++){
      for(int column = 0; column < camera.height / newHeight; column++){
        sum += depthFrame[row * camera.width + column];

      }
    }
    return matrix;
  }
}
