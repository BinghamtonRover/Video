import "dart:ffi";
import "dart:io";

import "package:opencv_ffi/opencv_ffi.dart";
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

  String getName();
  Pointer<RealSenseFrame> getDepthFrame();
  OpenCVImage? colorize(Pointer<RealSenseFrame> depthFrame);
}
