import "dart:ffi";
import "dart:typed_data";

import "package:burt_network/burt_network.dart";
import "package:video/video.dart";

/// A payload containing some data to report back to the parent isolate.
///
/// Instead of having nullable fields on this class, we subclass it and provide
/// only the relevant fields for each subclass. That way, for example, you cannot
/// accidentally send a frame without a [CameraDetails].
sealed class IsolatePayload { const IsolatePayload(); }

/// A container for a pointer to a native buffer that can be sent across isolates.
///
/// Sending a buffer across isolates would mean that data is copied, which is not ideal for
/// buffers containing an entire JPG image, from multiple isolates, multiple frames per second.
/// Since we cannot yet send FFI pointers across isolates, we have to send its raw address.
class FramePayload extends IsolatePayload {
  /// The details of the camera this frame came from.
  final CameraDetails details;

  /// The image to send.
  Uint8List? image;

  /// A const constructor.
  FramePayload({required this.details, this.image});
}

/// A class to send log messages across isolates. The parent isolate is responsible for logging.
class LogPayload extends IsolatePayload {
  /// The level to log this message.
  final LogLevel level;
  /// The message to log.
  final String message;
  /// The body of the message
  final String? body;
  /// A const constructor.
  const LogPayload({required this.level, required this.message, this.body});
}

/// A depth frame to be sent to the Autonomy program.
class DepthFramePayload extends IsolatePayload {
  /// The address of the data in memory, since pointers cannot be sent across isolates.
  final int address;
  /// Saves the address of the pointer to send across isolates.
  DepthFramePayload(Pointer<NativeFrames> pointer) :
    address = pointer.address;

  /// The native frame being referenced by this pointer.
  Pointer<NativeFrames> get frame => Pointer<NativeFrames>.fromAddress(address);

  /// Frees the memory associated with the frame.
  void dispose() => frame.dispose();
}

/// A container for data for the detected aruco tags
class ObjectDetectionPayload extends IsolatePayload {
  /// The details of the camera that sent the detection
  final CameraDetails details;

  /// The list of all the tags that were detected in the frame
  final List<DetectedObject> tags;

  /// Const constructor for detection payload, initializes
  /// the list of detected tags
  ObjectDetectionPayload({required this.details, required this.tags});
}
