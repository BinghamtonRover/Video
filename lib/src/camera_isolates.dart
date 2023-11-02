// ignore_for_file: avoid_print

import "dart:async";
import "dart:ffi";
import "dart:typed_data";

import "package:opencv_ffi/opencv_ffi.dart";
import "package:typed_isolate/typed_isolate.dart";
import "package:burt_network/burt_network.dart";
import "functions.dart";
import "frame.dart";
import "periodic_timer.dart";

class CameraIsolate extends IsolateChild<FrameData, VideoCommand>{
  /// The native camera object from OpenCV.
  late final Camera camera;

  /// Holds the current details of the camera.
  ///
  /// Use [updateDetails] to change this.
  final CameraDetails details;

  /// A timer to periodically send the camera status to the dashboard.
  Timer? statusTimer;

  /// A timer to read from the camera at an FPS given by [details].
  PeriodicTimer? frameTimer;

  /// A timer to log out the [fpsCount] every 5 seconds using [LoggerUtils.debug].
  Timer? fpsTimer;

  /// Records how many FPS this camera is actually running at.
  int fpsCount = 0;

  /// Creates a new manager for the given camera and default details.
  CameraIsolate({required CameraDetails this.details}) : super(id: details.name); 

  /// Whether the camera is running.
  bool get isRunning => frameTimer != null;

  /// The name of this camera (where it is on the rover).
  CameraName get name => details.name;

  @override
  Future<void> run() async {
    logger.verbose("Initializing camera: ${details.name}");
    camera = getCamera(name);
    statusTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => send(FrameData(details: details, address: 0, length: 0)),
    );
    if (!camera.isOpened) {
      logger.verbose("Camera $name is not connected");
      updateDetails(CameraDetails(status: CameraStatus.CAMERA_DISCONNECTED));
    }
    start();
  }

  @override
  void onData(VideoCommand data){
    //TODO
  }

  /// Updates the camera's [details], which will take effect on the next [sendFrame] call.
  ///
  /// This function echoes the details to the dashboard as part of the handshake protocol, and
  /// resets the timers in case the FPS has changed. Always use this function instead of modifying
  /// [details] directly so these steps are not forgotten.
  void updateDetails(CameraDetails newDetails) {
    details.mergeFromMessage(newDetails);
    send(FrameData(details: details, address: 0, length: 0));
    stop();
    start();
  }

  /// Disposes of the camera and the timers.
  void dispose() {
    logger.info("Releasing camera $name");
    camera.dispose();
    frameTimer?.cancel();
    fpsTimer?.cancel();
    statusTimer?.cancel();
  }

  /// Starts the camera and timers.
  void start() {
    if (isRunning || details.status != CameraStatus.CAMERA_ENABLED) return;
    logger.verbose("Starting camera $name");
    final interval = details.fps == 0
        ? Duration.zero
        : Duration(milliseconds: 1000 ~/ details.fps);
    frameTimer = PeriodicTimer(interval, sendFrame);
    fpsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      logger.debug("Camera $name sent ${fpsCount ~/ 5} frames");
      fpsCount = 0;
    });
  }

  /// Cancels all timers and stops reading the camera.
  void stop() {
    logger.verbose("Stopping camera $name");
    frameTimer?.cancel();
    fpsTimer?.cancel();
    frameTimer = null; // easy way to check if you're stopped
  }

  Future<void> sendFrame() async {
    final frame = camera.getJpg(quality: details.quality);
    if (frame == null) {
      updateDetails(CameraDetails(status: CameraStatus.CAMERA_NOT_RESPONDING));
    } else if (frame.data.length < 60000) {
      send(FrameData(address: frame.pointer.address, length: frame.data.length, details: details));
      fpsCount++;
    } else if (details.quality > 25) {
      logger.verbose("Lowering quality for $name");
      updateDetails(CameraDetails(quality: details.quality - 1));
    } else {
      logger.warning(
        "$name recorded a frame that was too large (${frame.data.length} bytes)",
      );
      updateDetails(CameraDetails(status: CameraStatus.FRAME_TOO_LARGE));
    }
  }
}