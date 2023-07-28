import "dart:io";
import "dart:async";
import "package:burt_network/burt_network.dart";
import "package:opencv_ffi/opencv_ffi.dart";
import "udp.dart";
import "constants.dart";
import "camera.dart";

/// Default details for a camera
/// 
/// Used when first creating the camera objects
final defaultDetails = CameraDetails(resolutionWidth: 300, resolutionHeight: 300, quality: 50, fps: 24, status: CameraStatus.CAMERA_ENABLED);

/// Returns the camera depending on device program is running
/// 
/// Uses [cameraNames] or [cameraIndexes]
Camera getCamera(CameraName name) => Platform.isWindows
  ? Camera.fromIndex(cameraIndexes[name]!)  
  : Camera.fromName(cameraNames[name]!);

/// Class to cotain all video devices
class VideoCollection{
  /// Holds a list of available cameras
  Map<CameraName, CameraManager> cameras = {
    for (final name in CameraName.values) 
      name: CameraManager(
        camera: getCamera(name),
        details: defaultDetails,
      )
  };

  /// [VideoServer] to send messages through
  /// 
  /// Defaualt port is 8002 for video 
  final videoServer = VideoServer(port: 8002);

  /// Function to initiliaze cameras
  Future<void> init() async{
    await videoServer.init();
    logger.info("Starting Cameras...");
    await connectCameras();
  }

  /// Connects to all [cameras]
  Future<void> connectCameras() async{
    for(final camera in cameras.values){
      await camera.init();
    }
  }
}

/// Holds all the devices connected
final collection = VideoCollection();
