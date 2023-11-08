import "dart:async";
import "dart:ffi";

import "package:opencv_ffi/opencv_ffi.dart";
import "package:typed_isolate/typed_isolate.dart";
import "package:burt_network/burt_network.dart";

import "collection.dart";
import "frame.dart";
import "camera_isolate.dart";

/// A parent isolate that spawns [CameraIsolate]s to manage the cameras.
/// 
/// With one isolate per camera, each camera can read in parallel. This class sends [VideoCommand]s
/// from the dashboard to the appropriate [CameraIsolate], and receives [FrameData]s which it uses
/// to read an [OpenCVImage] from native memory and send to the dashboard. By not sending the frame
/// from child isolate to the parent (just the pointer), we save a whole JPG image's worth of bytes
/// from every camera, every frame, every second. That could be up to 5 MB per second of savings.
class VideoController extends IsolateParent<VideoCommand, FrameData>{
  @override
  Future<void> run() async {
    for (final name in CameraName.values) {
      if (name == CameraName.CAMERA_NAME_UNDEFINED) continue;
      await spawn(
        CameraIsolate(
          logLevel: BurtLogger.level, 
          details: getDefaultDetails(name),
        ),
      );
    }
  }

  @override 
  void onData(FrameData data) {
    if (data.address == null) {
      collection.videoServer.sendMessage(VideoData(details: data.details));
    } else {      
      final frame = OpenCVImage(pointer: Pointer.fromAddress(data.address!), length: data.length!);
      collection.videoServer.sendMessage(VideoData(frame: frame.data, details: data.details));
      frame.dispose();
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
