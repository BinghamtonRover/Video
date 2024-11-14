import "dart:async";
import "dart:io";

import "package:burt_network/burt_network.dart";
import "package:opencv_ffi/opencv_ffi.dart";

import "package:video/video.dart";

/// Default details for a camera
///
/// Used when first creating the camera objects
CameraDetails getDefaultDetails(CameraName name) => CameraDetails(
  name: name,
  resolutionWidth: 600,
  resolutionHeight: 600,
  quality: 75,
  fps: 24,
  status: CameraStatus.CAMERA_ENABLED,
);

/// Default details for the RealSense camera.
///
/// These settings are balanced between autonomy depth and normal RGB.
CameraDetails getRealsenseDetails(CameraName name) => CameraDetails(
  name: name,
  resolutionWidth: 300,
  resolutionHeight: 300,
  quality: 50,
  fps: 0,
  status: CameraStatus.CAMERA_ENABLED,
);

/// Returns the camera depending on device program is running
///
/// Uses [cameraNames] or [cameraIndexes]
Camera getCamera(CameraName name) => Platform.isWindows
  ? Camera.fromIndex(cameraIndexes[name]!)
  : Camera.fromName(cameraNames[name]!);

/// Class to contain all video devices
class Collection extends Service {
  /// The [RoverSocket] to send messages through
  late final videoServer = RoverSocket(port: 8002, device: Device.VIDEO, collection: this);

  /// Main parent isolate
  final parent = CameraManager();

  /// Function to initialize cameras
  @override
  Future<bool> init() async {
    logger..trace("Running in trace mode")..debug("Running in debug mode");
    await parent.init();
    await videoServer.init();
    logger.info("Video program initialized");
    return true;
  }

  /// Stops all cameras and disconnects from the hardware.
  @override
  Future<void> dispose() async {
    parent.stopAll();
    await parent.dispose();
    await videoServer.dispose();
  }

  /// Restarts the video program.
  Future<void> restart() async {
    await dispose();
    await init();
  }
}

/// Holds all the devices connected
final collection = Collection();

/// Displays logs in the terminal and sends them to the Dashboard
final logger = BurtLogger(socket: collection.videoServer);
