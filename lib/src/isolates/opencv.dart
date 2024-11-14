//import "dart:ffi";
import "dart:typed_data";

//import "package:opencv_ffi/opencv_ffi.dart";
import "package:opencv_dart/opencv_dart.dart";
import "package:burt_network/burt_network.dart";

import "package:video/video.dart";
///Extension on `VideoCapture` to set camera properties as double values for `opencv_dart` compatibility.
///
///Provides easy access to adjust camera settings like resolution, FPS, zoom, focus, and orientation.
extension VideoCaptureUtils on VideoCapture {
  // ignore: public_member_api_docs
  void setResolution({required int width, required int height}) {
    set(3, width.toDouble());
    set(4, height.toDouble());
  }

  // ignore: public_member_api_docs
  int get fps => get(5).toInt();
  // ignore: public_member_api_docs
  set fps(int value) => set(5, value.toDouble());

  /// The zoom level of the camera.
  int get zoom => get(27).toInt();
  set zoom(int value) => set(27, value.toDouble());

  /// The focus of the camera.
  int get focus => get(28).toInt();
  set focus(int value) => set(28, value.toDouble());

  /// Pans the camera when zoomed in.
  int get pan => get(33).toInt();
  set pan(int value) => set(33, value.toDouble());

  /// Tilts the camera vertically when zoomed in.
  int get tilt => get(34).toInt();
  set tilt(int value) => set(34, value.toDouble());

  /// Rolls the camera when zoomed in.
  int get roll => get(35).toInt();
  set roll(int value) => set(35, value.toDouble());

  /// Determines whether autofocus is on or off
  int get autofocus => get(39).toInt();
  set autofocus(int value) => set(39, value.toDouble());
}
///An enxtension on 'Mat' to encode the matrix as a JPEG with a specified quality
///
///This method replaces the old encodeJPG from 'opencv_ffi' and instead uses imencode from 'opencv_dart'.
///Imencode returns the frame as a Uint8List and it also disposes the previous frame given so there 
///is no need for disposing it after.
extension MatrixUtils on Mat {
  // ignore: public_member_api_docs
  Uint8List? encodeJpg({required int quality}) {
    final params = VecI32.fromList([IMWRITE_JPEG_QUALITY, quality]);
    final (success, frame) = imencode(".jpg", this, params: params);
    return success ? frame : null;
  }
}

/// An isolate that is spawned to manage one camera.
/// 
/// This class accepts [VideoCommand]s and calls [updateDetails] with the newly-received details.
/// When a frame is read, instead of sending the [VideoData], this class sends only the pointer
// ignore: comment_references
/// to the [OpenCVImage] via the [IsolatePayload] class, and the image is read by the parent isolate.
class OpenCVCameraIsolate extends CameraIsolate {
  /// The native camera object from OpenCV.
  late final VideoCapture camera;
  /// Creates a new manager for the given camera and default details.
  OpenCVCameraIsolate({required super.details}); 

  @override
  void initCamera() {
    camera = getCamera(name);
    camera.setResolution(width: details.resolutionWidth, height: details.resolutionHeight);
    if (!camera.isOpened) {
      sendLog(LogLevel.warning, "Camera $name is not connected");
      updateDetails(CameraDetails(status: CameraStatus.CAMERA_DISCONNECTED));
    }
  }

  @override
  void disposeCamera() => camera.dispose();

  @override
  void updateDetails(CameraDetails newDetails, {bool restart = false}) {
    super.updateDetails(newDetails, restart: false);
    camera.setResolution(width: details.resolutionWidth, height: details.resolutionHeight);
    camera.zoom = details.zoom;
    camera.pan = details.pan;
    camera.tilt = details.tilt;
    camera.focus = details.focus;
    camera.autofocus = details.focus;
  }

  /// Reads a frame from the camera and sends it to the dashboard.
  /// 
  /// Checks for multiple errors along the way: 
  /// - If the camera does not respond, alerts the dashboard
  /// - If the frame is too large, reduces the quality (increases JPG compression)
  /// - If the quality is already low, alerts the dashboard
  @override
  void sendFrames() {
    final (success, matrix) = camera.read();
    if (!success) return;
    // detectAndAnnotateFrames(matrix);
    final frame = matrix.encodeJpg(quality: details.quality);
    
    
    if (frame == null) {  // Error getting the frame
      sendLog(LogLevel.warning, "Camera $name didn't respond");
      updateDetails(CameraDetails(status: CameraStatus.CAMERA_NOT_RESPONDING));
      return;
    } 

    sendFrame(frame, matrix.rows, matrix.cols);
    matrix.dispose();
    fpsCount++;
  }
}
