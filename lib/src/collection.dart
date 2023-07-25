// ignore_for_file: avoid_print
import "package:opencv_ffi/opencv_ffi.dart";

import "dart:async";

class VideoCollection{
  /// Holds a list of available cameras
  final cameras = <Camera>[];
  int cameraCount = 0; 

  void runCameras(){
    Timer.periodic(const Duration(milliseconds: 100), (run) {
      print("There are ${cameraCount + 1} running");
      for(int i = 0; i <= cameraCount; i++){
        cameras[i].showFrame();
      }
    });
  }

  Future<void> init() async{
    print("Starting Cameras...");
    final camera = Camera(cameraCount);
    cameras.add(camera);
    runCameras();
  }
}

final collection = VideoCollection();
