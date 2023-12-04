import "dart:async";
import "dart:io";

import "package:burt_network/burt_network.dart";
import "package:burt_network/logging.dart";
import "package:opencv_ffi/opencv_ffi.dart";

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
  /// [VideoServer] to send messages through
  ///
  /// Default port is 8002 for video
  final videoServer = VideoServer(port: 8002);

  /// Main parent isolate
  final parent = VideoController();
  
  /// Function to initialize cameras
  Future<void> init() async {
    logger..trace("Running in trace mode")..debug("Running in debug mode");
    await videoServer.init();
    await parent.run();
    logger.info("Video program initialized");
  }
}

/// Holds all the devices connected
final collection = Collection();
/// Displays logs in the terminal and sends them to the Dashboard
final logger = BurtLogger(socket: collection.videoServer);
