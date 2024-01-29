import "dart:ffi";
import "dart:io";

import "package:video/video.dart";

import "realsense_ffi.dart";
import "realsense_stub.dart";

abstract class RealSenseInterface {
  RealSenseInterface();
  factory RealSenseInterface.forPlatform() => Platform.isLinux ? RealSenseFFI() : RealSenseStub();
  
  bool init();
  void dispose();

  bool startStream();
  void stopStream();

  int get width;
  int get height;
  double get scale;

  String getName();
  Pointer<NativeFrames> getFrames();
}
