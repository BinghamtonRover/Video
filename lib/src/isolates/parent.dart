import "dart:async";
import "dart:io";

import "package:opencv_ffi/opencv_ffi.dart" as opencv;
import "package:typed_isolate/typed_isolate.dart";
import "package:burt_network/burt_network.dart";

import "package:video/video.dart";

/// The socket to send autonomy data to.
final autonomySocket = SocketInfo(address: InternetAddress("192.168.1.30"), port: 8003);

/// A parent isolate that spawns [CameraIsolate]s to manage the cameras.
///
/// With one isolate per camera, each camera can read in parallel. This class sends [VideoCommand]s
/// from the dashboard to the appropriate [CameraIsolate], and receives [IsolatePayload]s which it uses
/// to read an [opencv.OpenCVImage] from native memory and send to the dashboard. By not sending the frame
/// from child isolate to the parent (just the pointer), we save a whole JPG image's worth of bytes
/// from every camera, every frame, every second. That could be up to 5 MB per second of savings.
class CameraManager extends Service {
  /// The parent isolate that spawns the camera isolates.
  final parent = IsolateParent<VideoCommand, IsolatePayload>();

  StreamSubscription<VideoCommand>? _commands;
  StreamSubscription<IsolatePayload>? _data;

  @override
  Future<bool> init() async {
    _commands = collection.videoServer.messages.onMessage<VideoCommand>(
      name: VideoCommand().messageName,
      constructor: VideoCommand.fromBuffer,
      callback: _handleCommand,
    );
    parent.init();
    _data = parent.stream.listen(onData);

    for (final name in CameraName.values) {
      switch (name) {
        case CameraName.CAMERA_NAME_UNDEFINED: continue;
        case CameraName.ROVER_FRONT: continue;  // shares feed with AUTONOMY_DEPTH
        case CameraName.AUTONOMY_DEPTH:
          final details = getRealsenseDetails(name);
          final isolate = RealSenseIsolate(details: details);
          await parent.spawn(isolate);
        // All other cameras share the same logic, even future cameras
        default:  // ignore: no_default_cases
          final details = getDefaultDetails(name);
          final isolate = OpenCVCameraIsolate(details: details);
          await parent.spawn(isolate);
      }
    }
    return true;
  }

  @override
  Future<void> dispose() async {
    await _commands?.cancel();
    await _data?.cancel();
    await parent.dispose();
  }

  /// Handles data coming from the child isolates.
  ///
  /// - If a [DetailsPayload] comes, sends the details to the Dashboard
  /// - If a [FramePayload] comes, sends the frame and details to the Dashboard
  /// - If a [DepthFramePayload] comes, sends the depth data to autonomy
  /// - If a [LogPayload] comes, logs the message using [logger].
  void onData(IsolatePayload data) {
    switch (data) {
      case DetailsPayload():
        collection.videoServer.sendMessage(VideoData(details: data.details));
      case FramePayload(:final frame):
        collection.videoServer.sendMessage(VideoData(frame: frame.data, details: data.details));
        frame.dispose();
      case DepthFramePayload():
        collection.videoServer.sendMessage(VideoData(frame: data.frame.depthFrame), destination: autonomySocket);
        data.dispose();
      case LogPayload(): switch (data.level) {
        // Turns out using deprecated members when you *have* to still results in a lint.
        // See https://github.com/dart-lang/linter/issues/4852 for why we ignore it.
        case LogLevel.all: logger.info(data.message);
        // ignore: deprecated_member_use
        case LogLevel.verbose: logger.trace(data.message);
        case LogLevel.trace: logger.trace(data.message);
        case LogLevel.debug: logger.debug(data.message);
        case LogLevel.info: logger.info(data.message);
        case LogLevel.warning: logger.warning(data.message);
        case LogLevel.error: logger.error(data.message);
        // ignore: deprecated_member_use
        case LogLevel.wtf: logger.info(data.message);
        case LogLevel.fatal: logger.critical(data.message);
        // ignore: deprecated_member_use
        case LogLevel.nothing: logger.info(data.message);
        case LogLevel.off: logger.info(data.message);
      }
    }
  }

  /// Forwards the command to the appropriate camera.
  void _handleCommand(VideoCommand command) {
    collection.videoServer.sendMessage(command);  // echo the request
    parent.sendToChild(data: command, id: command.details.name);
  }

  /// Stops all the cameras managed by this class.
  void stopAll() {
    final command = VideoCommand(details: CameraDetails(status: CameraStatus.CAMERA_DISABLED));
    for (final name in CameraName.values) {
      if (name == CameraName.CAMERA_NAME_UNDEFINED) continue;
      if (name == CameraName.ROVER_FRONT) continue;
      parent.sendToChild(data: command, id: name);
    }
  }
}
