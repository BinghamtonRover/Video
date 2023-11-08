import "dart:async";

import "package:opencv_ffi/opencv_ffi.dart";
import "package:typed_isolate/typed_isolate.dart";
import "package:burt_network/burt_network.dart";
import "collection.dart";
import "frame.dart";
import "periodic_timer.dart";

/// An isolate that is spawned to manage one camera.
/// 
/// This class accepts [VideoCommand]s and calls [updateDetails] with the newly-received details.
/// When a frame is read, instead of sending the [VideoData], this class sends only the pointer
/// to the [OpenCVImage] via the [FrameData] class, and the image is read by the parent isolate.
class CameraIsolate extends IsolateChild<FrameData, VideoCommand>{
  /// The native camera object from OpenCV.
  late final Camera camera;
  /// Holds the current details of the camera.
  final CameraDetails details;

  /// A timer to periodically send the camera status to the dashboard.
  Timer? statusTimer;
  /// A timer to read from the camera at an FPS given by [details].
  PeriodicTimer? frameTimer;
  /// A timer to log out the [fpsCount] every 5 seconds using [LoggerUtils.debug].
  Timer? fpsTimer;
  /// Records how many FPS this camera is actually running at.
  int fpsCount = 0;

  /// The log level at which this isolate should be reporting.
  LogLevel logLevel;

  /// Creates a new manager for the given camera and default details.
  CameraIsolate({required this.details, required this.logLevel}) : super(id: details.name); 

  /// The name of this camera (where it is on the rover).
  CameraName get name => details.name;

  /// Sends the current status to the dashboard (with an empty frame).
  void sendStatus([_]) => send(FrameData(details: details, address: 0, length: 0));

  @override
  Future<void> run() async {
    Logger.level = logLevel;
    logger.debug("Initializing camera: $name");
    camera = getCamera(name);
    statusTimer = Timer.periodic(const Duration(seconds: 5), sendStatus);
    if (!camera.isOpened) {
      logger.warning("Camera $name is not connected");
      updateDetails(CameraDetails(status: CameraStatus.CAMERA_DISCONNECTED));
    }
    start();
  }

  @override
  void onData(VideoCommand data) => updateDetails(data.details);

  /// Updates the camera's [details], which will take effect on the next [sendFrame] call.
  void updateDetails(CameraDetails newDetails) {
    details.mergeFromMessage(newDetails);
    stop();
    start();
  }

  /// Disposes of the camera and the timers.
  void dispose() {
    camera.dispose();
    frameTimer?.cancel();
    fpsTimer?.cancel();
    statusTimer?.cancel();
    logger.info("Disposed camera $name");
  }

  /// Starts the camera and timers.
  void start() {
    if (details.status != CameraStatus.CAMERA_ENABLED) return;
    logger.debug("Starting camera $name. Status=${details.status}");
    final interval = details.fps == 0 ? Duration.zero : Duration(milliseconds: 1000 ~/ details.fps);
    frameTimer = PeriodicTimer(interval, sendFrame);
    fpsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      logger.trace("Camera $name sent ${fpsCount ~/ 5} frames");
      fpsCount = 0;
    });
  }

  /// Cancels all timers and stops reading the camera.
  void stop() {
    logger.debug("Stopping camera $name");
    frameTimer?.cancel();
    fpsTimer?.cancel();
  }

  /// Reads a frame from the camera and sends it to the dashboard.
  /// 
  /// Checks for multiple errors along the way: 
  /// - If the camera does not respond, alerts the dashboard
  /// - If the frame is too large, reduces the quality (increases JPG compression)
  /// - If the quality is already low, alerts the dashboard
  Future<void> sendFrame() async {
    final frame = camera.getJpg(quality: details.quality);
    if (frame == null) {  // Error getting the frame
      logger.warning("Camera $name didn't respond");
      updateDetails(CameraDetails(status: CameraStatus.CAMERA_NOT_RESPONDING));
    } else if (frame.data.length < 60000) {  // Frame can be sent
      send(FrameData(address: frame.pointer.address, length: frame.data.length, details: details));
      fpsCount++;
    } else if (details.quality > 25) {  // Frame too large, try lowering quality
      logger.debug("Lowering quality for $name from ${details.quality}");
      updateDetails(CameraDetails(quality: details.quality - 1));
    } else {  // Frame too large, cannot lower quality anymore
      logger.warning("$name's frames are too large (${frame.data.length} bytes, quality=${details.quality})");
      updateDetails(CameraDetails(status: CameraStatus.FRAME_TOO_LARGE));
    }
  }
}
