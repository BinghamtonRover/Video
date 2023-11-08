import "package:burt_network/burt_network.dart";

/// A container for a pointer to a native buffer that can be sent across isolates. 
/// 
/// Sending a buffer across isolates would mean that data is copied, which is not ideal for
/// buffers containing an entire JPG image, from multiple isolates, multiple frames per second.
/// Since we cannot yet send FFI pointers across isolates, we have to send its raw address
/// instead. 
class FrameData {
  /// The [CameraDetails] for this frame.
  final CameraDetails details;
  /// The address of the FFI pointer containing the image.
  final int? address;
  /// The amount of bytes to read past [address].
  final int? length;

  /// Creates a [FrameData] containing an actual frame.
  FrameData({required this.details, required this.address, required this.length});
  /// Creates a [FrameData] that only has [CameraDetails].
  FrameData.details(this.details) : address = null, length = null;
}
