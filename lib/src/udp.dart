import "package:burt_network/burt_network.dart";
import "collection.dart";

/// Class for the video program to interact with the dashboard
class VideoServer extends ServerSocket{
  /// Requires a port to communicate through
  VideoServer({required super.port}) : super(device: Device.VIDEO);

  @override
  void onMessage(WrappedMessage wrapper) {
    // ignore message if not a video message
    if(wrapper.name != VideoCommand().messageName) return;
    // Return the message to tell dashboard the message was received
    sendMessage(wrapper);
    final command = VideoCommand.fromBuffer(wrapper.data);
    // Send LOADING before making any changes
    sendMessage(VideoData(id: command.id, details: CameraDetails(status: CameraStatus.CAMERA_LOADING)));
    // Change the settings
    collection.cameras[command.details.name]!.updateDetails(details: command.details);    
  }
}
