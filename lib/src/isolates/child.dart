import "dart:async";

import "package:burt_network/burt_network.dart";
import "package:typed_isolate/typed_isolate.dart";
import "package:opencv_ffi/opencv_ffi.dart";

import "package:video/video.dart";
import "fps_reporter.dart";

/// The maximum size of a UDP packet, in bytes (minus a few to be safe).
const maxPacketLength = 60000;

/// A child isolate that manages a single camera and streams frames from it.
abstract class CameraIsolate extends IsolateChild<IsolatePayload, VideoCommand> with FpsReporter {
  /// Holds the current details of the camera.
  final CameraDetails details;
  /// A constructor with initial details.
  CameraIsolate({required this.details}) : super(id: details.name);

  /// A timer to periodically send the camera status to the dashboard.
  Timer? statusTimer;
  /// A timer to read from the camera at an FPS given by [details].
  Timer? frameTimer;

  /// Whether the camera is currently reading a frame.
  bool isReadingFrame = false;

  /// The name of this camera (where it is on the rover).
  CameraName get name => details.name;

  /// Sends the current status to the dashboard.
  void sendStatus([_]) => send(DetailsPayload(details));

  /// Logs a message by sending a [LogPayload] to the parent isolate.
  ///
  /// Note: it is important to _not_ log this message directly in _this_ isolate, as it will
  /// not be configurable by the parent isolate and will not be sent to the Dashboard.
  @override
  void sendLog(LogLevel level, String message) => send(LogPayload(level: level, message: message));

  @override
  Future<void> run() async {
    sendLog(LogLevel.debug, "Initializing camera: $name");
    statusTimer = Timer.periodic(const Duration(seconds: 5), sendStatus);
    start();
  }

  /// Disposes of this camera and all other resources.
  ///
  /// After running this, the camera should need to be opened again.
  void dispose() {
    stop();
    statusTimer?.cancel();
  }

  @override
  void onData(VideoCommand data) => updateDetails(data.details);

  /// Updates the camera's [details], which will take effect on the next [sendFrame] call.
  void updateDetails(CameraDetails newDetails) {
    final shouldRestart = (newDetails.hasFps() && newDetails.fps != details.fps)
      || (newDetails.hasResolutionHeight() && newDetails.resolutionHeight != details.resolutionHeight)
      || (newDetails.hasResolutionWidth() && newDetails.resolutionWidth != details.resolutionWidth);
    details.mergeFromMessage(newDetails);
    if (shouldRestart) {
      stop();
      if (details.status != CameraStatus.CAMERA_DISABLED) start();
    }
  }

  /// Initializes the camera and starts streaming.
  void initCamera();

  /// Closes and releases the camera.
  ///
  /// This is separate from [dispose] so the isolate can keep reporting its status.
  void disposeCamera();

  /// Reads frame/s from the camera and sends it/them.
  Future<void> sendFrames();

  /// Sends an individual frame to the dashboard.
  ///
  /// This function also checks if the frame is too big to send, and if so,
  /// lowers the JPG quality by 1%. If the quality reaches 25% (visually noticeable),
  /// an error is logged instead.
  void sendFrame(OpenCVImage image, {CameraDetails? detailsOverride}) {
    final details = detailsOverride ?? this.details;
    if (image.data.length < maxPacketLength) {  // Frame can be sent
      send(FramePayload(details: details, image: image));
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
    initCamera();
    if (details.status != CameraStatus.CAMERA_ENABLED) return;
    sendLog(LogLevel.debug, "Starting camera $name. Status=${details.status}");
    final interval = details.fps == 0 ? Duration.zero : Duration(milliseconds: 1000 ~/ details.fps);
    frameTimer = Timer.periodic(interval, _frameCallback);
    startFps();
  }

  Future<void> _frameCallback(Timer timer) async {
    if (isReadingFrame) return;
    isReadingFrame = true;
    await sendFrames();
    isReadingFrame = false;
  }

  /// Cancels all timers and stops reading the camera.
  void stop() {
    sendLog(LogLevel.debug, "Stopping camera $name");
    disposeCamera();
    frameTimer?.cancel();
    stopFps();
  }
}
