import "dart:async";

import "package:burt_network/burt_network.dart";
import "package:burt_network/logging.dart";
import "package:typed_isolate/typed_isolate.dart";
import "package:opencv_ffi/opencv_ffi.dart";

import "package:video/video.dart";

const maxPacketLength = 60000;  // max UDP packet size in bytes

extension on CameraDetails {
  bool get interferesWithAutonomy => hasResolutionHeight()
    || hasResolutionWidth()
    || hasFps()
    || hasStatus();
}

abstract class CameraIsolate extends IsolateChild<IsolatePayload, VideoCommand> {
  /// Holds the current details of the camera.
  final CameraDetails details;
  CameraIsolate({required this.details}) : super(id: details.name);

  /// A timer to periodically send the camera status to the dashboard.
  Timer? statusTimer;
  /// A timer to read from the camera at an FPS given by [details].
  PeriodicTimer? frameTimer;
  /// A timer to log out the [fpsCount] every 5 seconds using [sendLog].
  Timer? fpsTimer;
  /// Records how many FPS this camera is actually running at.
  int fpsCount = 0;

  /// The name of this camera (where it is on the rover).
  CameraName get name => details.name;

  /// Sends the current status to the dashboard.
  void sendStatus([_]) => send(DetailsPayload(details));

  /// Logs a message by sending a [LogPayload] to the parent isolate.
  /// 
  /// Note: it is important to _not_ log this message directly in _this_ isolate, as it will
  /// not be configurable by the parent isolate and will not be sent to the Dashboard.
  void sendLog(LogLevel level, String message) => send(LogPayload(level: level, message: message));

  @override
  Future<void> run() async {
    sendLog(LogLevel.debug, "Initializing camera: $name");
    initCamera();
    statusTimer = Timer.periodic(const Duration(seconds: 5), sendStatus);
    start();
  }

  @override
  void onData(VideoCommand data) {
    if (data.details.interferesWithAutonomy) {
      sendLog(LogLevel.error, "That would break autonomy");
    } else {
      updateDetails(data.details);
    }
  }

  /// Updates the camera's [details], which will take effect on the next [sendFrame] call.
  void updateDetails(CameraDetails newDetails) {
    details.mergeFromMessage(newDetails);
    stop();
    start();
  }

  void dispose() {
    disposeCamera();
    frameTimer?.cancel();
    fpsTimer?.cancel();
    statusTimer?.cancel();
  }

  void initCamera();
  void disposeCamera();
  void sendFrames();

  void sendFrame(OpenCVImage image, {CameraDetails? detailsOverride}) {
    final details = detailsOverride ?? this.details;
    if (image.data.length < maxPacketLength) {  // Frame can be sent
      send(FramePayload(details: details, address: image.pointer.address, length: image.data.length));
    } else if (details.quality > 25) {  // Frame too large, lower quality
      sendLog(LogLevel.debug, "Lowering quality for $name from ${details.quality}");
      details.quality -= 1;  // maybe next frame can send
    } else {  // Frame too large, quality cannot be lowered
      sendLog(LogLevel.warning, "Frame from camera $name are too large (${image.data.length})");
      updateDetails(CameraDetails(status: CameraStatus.FRAME_TOO_LARGE));
    }
  }

  /// Starts the camera and timers.
  void start() {
    if (details.status != CameraStatus.CAMERA_ENABLED) return;
    sendLog(LogLevel.debug, "Starting camera $name. Status=${details.status}");
    final interval = details.fps == 0 ? Duration.zero : Duration(milliseconds: 1000 ~/ details.fps);
    frameTimer = PeriodicTimer(interval, sendFrames);
    fpsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      sendLog(LogLevel.trace, "Camera $name sent ${fpsCount ~/ 5} frames");
      fpsCount = 0;
    });
  }
  
  /// Cancels all timers and stops reading the camera.
  void stop() {
    sendLog(LogLevel.debug, "Stopping camera $name");
    frameTimer?.cancel();
    fpsTimer?.cancel();
  }
}
