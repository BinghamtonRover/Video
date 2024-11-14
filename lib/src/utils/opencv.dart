import "dart:typed_data";

import "package:opencv_dart/opencv_dart.dart";

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
