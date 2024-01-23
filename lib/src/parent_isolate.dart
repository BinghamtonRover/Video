import "dart:async";

import "package:opencv_ffi/opencv_ffi.dart";
import "package:typed_isolate/typed_isolate.dart";
import "package:burt_network/burt_network.dart";
import "package:burt_network/logging.dart";

import "collection.dart";
import "frame.dart";
import "camera_isolate.dart";

/// A parent isolate that spawns [CameraIsolate]s to manage the cameras.
/// 
/// With one isolate per camera, each camera can read in parallel. This class sends [VideoCommand]s
/// from the dashboard to the appropriate [CameraIsolate], and receives [IsolatePayload]s which it uses
/// to read an [OpenCVImage] from native memory and send to the dashboard. By not sending the frame
/// from child isolate to the parent (just the pointer), we save a whole JPG image's worth of bytes
/// from every camera, every frame, every second. That could be up to 5 MB per second of savings.
class VideoController extends IsolateParent<VideoCommand, IsolatePayload>{
  @override
  Future<void> run() async {
    for (final name in CameraName.values) {
      if (name == CameraName.CAMERA_NAME_UNDEFINED) continue;
      await spawn(
        CameraIsolate(
          details: getDefaultDetails(name),
        ),
      );
    }
  }

  @override 
  void onData(IsolatePayload data) {
    switch (data) {
      case DetailsPayload(): 
        collection.videoServer.sendMessage(VideoData(details: data.details));
      case FramePayload():
        final frame = data.getFrame();
        collection.videoServer.sendMessage(VideoData(frame: frame.data, details: data.details));
        frame.dispose();
      case LogPayload(): switch (data.level) {
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

  /// Stops all the cameras managed by this class.
  void stopAll() {
    final command = VideoCommand(details: CameraDetails(status: CameraStatus.CAMERA_DISABLED));
    for (final name in CameraName.values) {
      if (name == CameraName.CAMERA_NAME_UNDEFINED) continue;
      send(command, name);
    }
  }
}
