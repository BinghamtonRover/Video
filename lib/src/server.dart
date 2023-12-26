import "package:burt_network/burt_network.dart";

import "collection.dart";

/// Class for the video program to interact with the dashboard
class VideoServer extends ServerSocket {
  /// Requires a port to communicate through
  VideoServer({required super.port}) : super(device: Device.VIDEO);

  @override
  void onMessage(WrappedMessage wrapper) {
    // ignore message if not a video message
    if (wrapper.name != VideoCommand().messageName) return;
    final command = VideoCommand.fromBuffer(wrapper.data);
    sendMessage(command);  // Echo the request
    collection.parent.send(command, command.details.name);
  }
}

/// Class for the video program to interact with the autuonomy systems
class AutonomyServer extends ServerSocket {
  /// Requires a port to communicate through 
  AutonomyServer({required super.port}) : super(device: Device.AUTONOMY);

  /// Dummy (non-used) overridden function
  @override
  void onMessage(WrappedMessage wrapper) {}

  late final Camera roverFront;
  

  sendMessage()
}