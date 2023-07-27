// ignore_for_file: avoid_print
import "dart:io";
import "dart:async";
import "package:burt_network/burt_network.dart";
import "package:opencv_ffi/opencv_ffi.dart";
import "udp.dart";
import "constants.dart";
import "camera.dart";




class VideoCollection{
  /// Holds a list of available cameras
  Map<String, CameraManager> cameras = {};

  int cameraCount = 0; 

  final videoServer = VideoServer(port: 8002);

  Future<void> init() async{
    await videoServer.init();
    print("Starting Cameras...");
    connectCameras();
  }

  void connectCameras(){
    final cameraDetails = CameraDetails(resolutionWidth: 300, resolutionHeight: 300, quality: 50, fps: 24, status: CameraStatus.CAMERA_ENABLED);
    for(int i = 0; i < cameraNames.length; ++i){
      cameraDetails.mergeFromMessage(CameraDetails(name: cameraIndexes.values.elementAt(i)));
      if(Platform.isWindows){
        cameras[cameraIndexes.keys.elementAt(i)] = CameraManager(camera: Camera.fromIndex(int.parse(cameraIndexes.keys.elementAt(i))), details: cameraDetails);
      } else {
        cameras[cameraNames.keys.elementAt(i)] = CameraManager(camera: Camera.fromName(cameraNames.keys.elementAt(i)), details: cameraDetails);   
      }
    }
  }
}

final collection = VideoCollection();
