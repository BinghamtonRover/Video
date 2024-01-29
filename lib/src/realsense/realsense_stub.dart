import "dart:ffi";

import "package:video/video.dart";

class RealSenseStub extends RealSenseInterface {
  @override
  bool init() => true;

  @override void dispose() { }

  @override bool startStream() => true;
  @override void stopStream() { }

  @override int get width => 0;
  @override int get height => 0;
  @override double get scale => 0;


  @override String getName() => "Virtual RealSense";
  @override Pointer<NativeFrames> getFrames() => nullptr;
}
