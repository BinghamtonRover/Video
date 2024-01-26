import "dart:ffi";

import "package:opencv_ffi/opencv_ffi.dart";
import "package:video/video.dart";

class RealSenseStub extends RealSenseInterface {
  @override
  bool init() => true;

  @override void dispose() { }

  @override bool startStream() => true;
  @override void stopStream() { }

  @override String getName() => "Virtual RealSense";
  @override Pointer<RealSenseFrame> getDepthFrame() => nullptr;
  @override OpenCVImage? colorize(Pointer<RealSenseFrame> depthFrame, {int quality = 75}) => null;
}
