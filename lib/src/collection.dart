// ignore_for_file: avoid_print
import "package:burt_network/burt_network.dart";
import "package:opencv_ffi/opencv_ffi.dart";
import "udp.dart";
import "dart:async";

class VideoCollection{
  /// Holds a list of available cameras
  final cameras = <Camera>[];

  int cameraCount = 0; 

  final videoServer = VideoServer(port: 8002);

  void addCamera(int index){
    final camera = Camera.fromIndex(index);
    cameras.add(camera);
    cameraCount++;
  }

  void runCameras(){
    Timer.periodic(const Duration(milliseconds: 100), (run) {
      print("There are ${cameraCount + 1} running");
      for(int i = 0; i < cameraCount; i++){
        //cameras[i].showFrame();
        final frame = cameras[i].getJpg();
        if(frame == null){
          videoServer.sendMessage(VideoData(details: CameraDetails(name: CameraName.ROVER_FRONT, status: CameraStatus.CAMERA_NOT_RESPONDING)));
        } else {
          videoServer.sendMessage(VideoData(frame: frame.data, details: CameraDetails(name: CameraName.ROVER_FRONT, status: CameraStatus.CAMERA_ENABLED)));
          frame.dispose();
        }
      }
    });
  }

  Future<void> init() async{
    await videoServer.init();
    print("Starting Cameras...");
    runCameras();
  }
}

final collection = VideoCollection();
