import "package:burt_network/burt_network.dart";
import "package:opencv_ffi/opencv_ffi.dart";
import "dart:async";
import "collection.dart";

/// Class to manage [Camera] objects 
class CameraManager {
  /// Camera that is being controlled
  late final Camera camera;
  /// Holds the current details of the camera
  late final CameraDetails details;
  /// Timer that is run constantly to send frames
  Timer? timer;

  /// Constructor
  CameraManager({required this.camera, required this.details});

  /// Initializes the timer
  Future<void> init() async{  
    if(!camera.isOpened){
      details.mergeFromMessage(CameraDetails(status: CameraStatus.CAMERA_DISCONNECTED));
      return;
    }
    timer = Timer.periodic(Duration(milliseconds: 1000 ~/ details.fps), (runner) {
      sendFrame();
    });
  }

  /// disposes of the camera and the timer
  void dispose(){  
    camera.dispose();
    timer?.cancel();
  }

  /// Updates the current details 
  /// 
  /// reset the timer for FPS if needed, change resolution, enable or disable
  void updateDetails({required CameraDetails details}){  
    details.mergeFromMessage(details);
  }

  /// Sends frame to dashboard
  /// 
  /// If the camera was connected and then returns a null frame then its status changes to [CameraStatus.CAMERA_NOT_RESPONDING]
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
}
