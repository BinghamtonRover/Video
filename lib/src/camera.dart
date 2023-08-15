import "package:burt_network/burt_network.dart";
import "package:opencv_ffi/opencv_ffi.dart";
import "dart:async";
import "collection.dart";

/// Prints the actual FPS of this camera at the debug [LogLevel].
const bool countFps = false;

/// Class to manage [Camera] objects 
class CameraManager {
  /// Camera that is being controlled
  Camera camera;
  /// Holds the current details of the camera
  CameraDetails details;
  /// Timer that is run constantly to send frames
  Timer? timer;
  bool _isLoading = false;

  /// Records how many FPS this camera is actually running at. Enable [countFps] to see it in the logs.
  int fpsCount = 0;

  /// Constructor
  CameraManager({required this.camera, required this.details});

  /// The name of this camera (where it is on the rover).
  CameraName get name => details.name;

  /// Starts the camera and FPS timers.
  void startTimer() {
    final delay = details.fps == 0 ? Duration.zero : Duration(milliseconds: 1000 ~/ details.fps);
    logger.verbose("Waiting for delay: $delay");
    timer?.cancel();
    timer = Timer.periodic(delay, sendFrame);
    if (countFps) Timer.periodic(const Duration(seconds: 5), (_) {logger.debug("Sent ${fpsCount ~/ 5} frames"); fpsCount = 0;});
  }

  /// Initializes the timer
  Future<void> init() async{  
    if (camera.isOpened){
      logger.verbose("Initializing camera: ${details.name}");
      startTimer();      
    } else {
      logger.verbose("Camera $name is not connected");
      details.status = CameraStatus.CAMERA_DISCONNECTED;
    }
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
    this.details.mergeFromMessage(details);
    startTimer();
  }

  /// Sends frame to dashboard
  /// 
  /// If the camera was connected and then returns a null frame then its status changes to [CameraStatus.CAMERA_NOT_RESPONDING]
  void sendFrame(_) {  // run this with the timer. Read frame, send to dashboard, handle errors
    if (_isLoading) return;
    if (countFps) fpsCount++;
    _isLoading = true;
    final frame = camera.getJpg(quality: details.quality);
    collection.videoServer.sendMessage(VideoData(details: details));
    if (frame == null) {
      details.status = CameraStatus.CAMERA_NOT_RESPONDING;
      collection.videoServer.sendMessage(VideoData(details: details));
      timer?.cancel();
    } else {
      if(frame.data.length < 60000){
        details.status = CameraStatus.CAMERA_ENABLED;
        collection.videoServer.sendMessage(VideoData(frame: frame.data, details: details));
      } else {
        details.status = CameraStatus.FRAME_TOO_LARGE;
        collection.videoServer.sendMessage(VideoData(details: details));
        if(details.quality > 25){
          details.quality--;
        } else {
          timer?.cancel();
          details.status = CameraStatus.FRAME_TOO_LARGE;
        }
      }
      frame.dispose();
    }
    _isLoading = false;
  }
}
