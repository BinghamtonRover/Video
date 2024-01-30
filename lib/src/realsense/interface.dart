import "dart:ffi";
import "dart:io";

import "package:video/video.dart";

import "realsense_ffi.dart";
import "realsense_stub.dart";

/// An interface for reading the RealSense camera.
abstract class RealSenseInterface {
  /// A const constructor.
  const RealSenseInterface();
  /// Decides which implementation to use depending on platform.
  factory RealSenseInterface.forPlatform() => Platform.isLinux ? RealSenseFFI() : RealSenseStub();
  
  /// Initializes the RealSense. Returns whether the initialization was successful.
  bool init();
  /// Releases the RealSense. Calling [init] again should re-open the device.
  void dispose();

  /// Starts the RealSense stream and waits for a valid frame.
  bool startStream();
  /// Stops the stream but keeps the device alive.
  void stopStream();

  /// The width of the frames.
  int get width;
  /// The height of the frames.
  int get height;
  /// The depth scale -- each pixel in the depth frame is an integer multiple of this, in meters.
  double get scale;

  /// Gets the name and model of the camera.
  String getName();
  /// Gets the currently available frames. May return [nullptr].
  Pointer<NativeFrames> getFrames();
}
