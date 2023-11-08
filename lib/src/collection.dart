import "dart:async";
import "dart:io";
import "dart:isolate";

import "package:burt_network/burt_network.dart";
import "package:opencv_ffi/opencv_ffi.dart";
import "package:typed_isolate/typed_isolate.dart";

import "camera.dart";
import "camera_isolates.dart";
import "constants.dart";
import "parent_isolate.dart";
import "server.dart";

/// Default details for a camera
///
/// Used when first creating the camera objects
CameraDetails getDefaultDetails(CameraName name) => CameraDetails(
      name: name,
      resolutionWidth: 300,
      resolutionHeight: 300,
      quality: 50,
      fps: 24,
      status: CameraStatus.CAMERA_ENABLED,
    );

/// Returns the camera depending on device program is running
///
/// Uses [cameraNames] or [cameraIndexes]
Camera getCamera(CameraName name) => Platform.isWindows
    ? Camera.fromIndex(cameraIndexes[name]!)
    : Camera.fromName(cameraNames[name]!);

/// Class to contain all video devices
class Collection {
  /// Holds a list of available cameras
  Map<CameraName, Isolate> cameras = {};

  /// [VideoServer] to send messages through
  ///
  /// Default port is 8002 for video
  final videoServer = VideoServer(port: 8002);

  /// Main parent isolate
  final parent = VideoController();
  
  /// Function to initialize cameras
  Future<void> init() async {
    await videoServer.init();
    cameras = {
      for(final name in CameraName.values)
        name: await parent.spawn(CameraIsolate(details: getDefaultDetails(CameraName.ROVER_FRONT)))
    };
    await parent.run();
    logger.info("Video program initialized");
  }
}

/// Holds all the devices connected
final collection = Collection();
