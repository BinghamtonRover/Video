import "package:burt_network/burt_network.dart";
import "package:opencv_ffi/opencv_ffi.dart";
import "dart:async";
import "collection.dart";

class CameraManager {
  late final Camera camera;
  late final CameraDetails details;
  Timer? timer;

  CameraManager({required this.camera, required this.details});

  Future<void> init() async{  // init the timer 
    if(!camera.isOpened){
      details.mergeFromMessage(CameraDetails(status: CameraStatus.CAMERA_DISCONNECTED));
      return;
    }
    timer = Timer.periodic(Duration(milliseconds: 1000 ~/ details.fps), (runner) {
      sendFrame();
    });
  }

  void dispose(){  // dispose the camera and the timer
    camera.dispose();
    timer?.cancel();
  }

  void updateDetails({required CameraDetails details}){  // reset the timer for FPS if needed, change resolution, enable or disable
    details.mergeFromMessage(details);
  }

  void sendFrame(){  // run this with the timer. Read frame, send to dashboard, handle errors
    final frame = camera.getJpg();
    if(frame == null){
      updateDetails(details: CameraDetails(status: CameraStatus.CAMERA_NOT_RESPONDING));
      collection.videoServer.sendMessage(VideoData(details: details));
      timer?.cancel();
    } else {
      collection.videoServer.sendMessage(VideoData(frame: frame.data, details: CameraDetails(name: CameraName.ROVER_FRONT, status: CameraStatus.CAMERA_ENABLED)));
      frame.dispose();
    }
  }

  bool get isOpened => camera.isOpened;
}
