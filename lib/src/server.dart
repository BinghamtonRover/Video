import "dart:io";

import "package:burt_network/burt_network.dart";

import "collection.dart";

final autonomySocket = SocketInfo(address: InternetAddress("192.168.1.30"), port: 8003);

/// Class for the video program to interact with the dashboard
class VideoServer extends RoverServer {
  /// Requires a port to communicate through
  VideoServer({required super.port}) : super(device: Device.VIDEO);

  @override
  void onMessage(WrappedMessage wrapper) {
    // ignore message if not a video message
    if (wrapper.name != VideoCommand().messageName) return;
    final command = VideoCommand.fromBuffer(wrapper.data);
    sendMessage(command);  // Echo the request
    collection.parent.send(data: command, id: command.details.name);
  }

  void sendDepthFrame(VideoData frame) => 
    sendMessage(frame, destinationOverride: autonomySocket);

  @override
  void restart() => collection.restart();
}
