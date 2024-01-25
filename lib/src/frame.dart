import "dart:ffi";
import "dart:typed_data";

import "package:burt_network/burt_network.dart";
import "package:burt_network/logging.dart";
import "package:opencv_ffi/opencv_ffi.dart";
import "package:video/video.dart";

/// A payload containing some data to report back to the parent isolate.
/// 
/// Instead of having nullable fields on this class, we subclass it and provide
/// only the relevant fields for each subclass. That way, for example, you cannot
/// accidentally send a frame without a [CameraDetails].
sealed class IsolatePayload { const IsolatePayload(); }

/// A payload representing the status of the given camera. 
class DetailsPayload extends IsolatePayload {
  /// The details being sent.
  final CameraDetails details;
  /// A const constructor.
  const DetailsPayload(this.details);
}

/// A container for a pointer to a native buffer that can be sent across isolates. 
/// 
/// Sending a buffer across isolates would mean that data is copied, which is not ideal for
/// buffers containing an entire JPG image, from multiple isolates, multiple frames per second.
/// Since we cannot yet send FFI pointers across isolates, we have to send its raw address.
class FramePayload extends IsolatePayload {
  /// The details of the camera this frame came from.
  final CameraDetails details;
  /// The address in FFI memory this frame starts at.
  final int address;
  /// The length of this frame in bytes.
  final int length;

  /// A const constructor.
  const FramePayload({required this.details, required this.address, required this.length});

  /// The underlying data held at [address]. 
  /// 
  /// This cannot be a normal field as [Pointer]s cannot be sent across isolates, and this should
  /// not be a getter because the underlying memory needs to be freed and cannot be used again. 
  OpenCVImage getFrame() => OpenCVImage(pointer: Pointer.fromAddress(address), length: length);
}

/// A class to send log messages across isolates. The parent isolate is responsible for logging.
class LogPayload extends IsolatePayload {
  /// The level to log this message.
  final LogLevel level;
  /// The message to log.
  final String message;
  /// A const constructor.
  const LogPayload({required this.level, required this.message});
}

class DepthFramePayload extends IsolatePayload {
  final int address;  // uint8_t*
  final int length;
  final int framesAddress;
  const DepthFramePayload({
    required this.address,
    required this.length,
    required this.framesAddress,
  });

  Uint8List get depthFrame => Pointer<Uint8>.fromAddress(address).asTypedList(length);
  Pointer<BurtRsFrames> get framesPointer => Pointer<BurtRsFrames>.fromAddress(framesAddress);
}
