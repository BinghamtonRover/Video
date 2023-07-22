// ignore_for_file: avoid_print
import "package:opencv_ffi/opencv_ffi.dart";

class VideoCollection{
  /// Holds a list of available cameras
  var cameras = List<Camera>;

  void start(){
    print("Starting Cameras...");
  }
}
void main() {
	print("The main program has not yet been implemented");
  final collection = VideoCollection()..start();
}
