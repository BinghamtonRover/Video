import "dart:io";
import "dart:async";
import "package:burt_network/burt_network.dart";
import "package:opencv_ffi/opencv_ffi.dart";
import "udp.dart";
import "constants.dart";
import "camera.dart";

final defaultDetails = CameraDetails(resolutionWidth: 300, resolutionHeight: 300, quality: 50, fps: 24, status: CameraStatus.CAMERA_ENABLED);

Camera getCamera(CameraName name) => Platform.isWindows
  ? Camera.fromIndex(cameraIndexes[name]!)  
  : Camera.fromName(cameraNames[name]!);

class VideoCollection{
  /// Holds a list of available cameras
  Map<String, CameraManager> cameras = {
    for (final name in CameraName.values) 
      name.toString(): CameraManager(
        camera: getCamera(name),
        details: defaultDetails,
      )
  };

  final videoServer = VideoServer(port: 8002);

  Future<void> init() async{
    await videoServer.init();
    logger.info("Starting Cameras...");
    connectCameras();
  }

  void connectCameras(){
    for(final camera in cameras.values){
      camera.init();
    }
  }
}

final collection = VideoCollection();
