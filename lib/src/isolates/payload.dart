import "dart:ffi";

import "package:burt_network/burt_network.dart";
import "package:opencv_ffi/opencv_ffi.dart" show OpenCVImage; //ArucoMarkers, ArucoMarker, ArucoMarkersUtils, OpenCVImage ;

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
  FramePayload({required this.details, required OpenCVImage image}) : 
    address = image.pointer.address,
    length = image.data.length;

  /// The underlying data held at [address]. 
  /// 
  /// This cannot be a normal field as [Pointer]s cannot be sent across isolates, and this should
  /// not be a getter because the underlying memory needs to be freed and cannot be used again. 
  OpenCVImage get frame => OpenCVImage(pointer: Pointer.fromAddress(address), length: length);

  /// Frees the data in this frame.
  void dispose() => frame.dispose();
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

/// Update: no longer sending depth frames
/// Processing will be done on the video program -> Detection of obstacles will be sent to autonomy
class AutonomyPayload extends IsolatePayload {
  /// VideoData without a frame sent to autonomy so it can make decisions
  VideoData data;
  /// Constructor 
  AutonomyPayload(this.data); 
}
