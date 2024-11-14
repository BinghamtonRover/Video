import "dart:ffi";
import "dart:typed_data";

import "package:opencv_dart/opencv_dart.dart";
import "package:video/realsense.dart";

/// Useful methods to adjust settings of an OpenCV video device.
extension VideoCaptureUtils on VideoCapture {
  /// Sets the resolution of the device.
  void setResolution({required int width, required int height}) {
    set(3, width.toDouble());
    set(4, height.toDouble());
  }

  /// The frames per second the device will record, independent of calls to [read].
  int get fps => get(5).toInt();
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

/// Useful methods on OpenCV images.
extension MatrixUtils on Mat {
  /// Encodes this image as a JPG with the given quality.
  Uint8List? encodeJpg({required int quality}) {
    final params = VecI32.fromList([IMWRITE_JPEG_QUALITY, quality]);
    final (success, frame) = imencode(".jpg", this, params: params);
    return success ? frame : null;
  }
}

/// Converts raw data in native memory to an OpenCV image.
extension Uint8ToMat on Pointer<Uint8> {
  /// Reads this 1-dimensional list as an OpenCV image.
  Mat toOpenCVMat(Resolution resolution, {int? length}) {
    length ??= resolution.width * resolution.height;
    return Mat.fromList(resolution.height, resolution.width, MatType.CV_8UC3, asTypedList(length));
  }
}
