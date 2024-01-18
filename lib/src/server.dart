import "package:burt_network/burt_network.dart";
import "dart:io";

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

// /// Class for the video program to interact with the autuonomy systems
// class AutonomyServer extends ProtoSocket {
//   /// Requires a port to communicate through 

// 	AutonomyServer({required super.port, required InternetAddress address}) : super(
// 		device: Device.AUTONOMY,
// 		heartbeatInterval: const Duration(seconds: 1),
// 		destination: SocketInfo(
// 			address: address, 
// 			port: 8001,
// 		),
// 	);

//   @override
// 	Future<void> checkHeartbeats() async { }

//   /// Dummy (non-used) overridden function
//   @override
//   void onMessage(WrappedMessage wrapper) {
//     // ignore message if not a video message
//     // if (wrapper.name != VideoCommand().messageName) return;
//     // final command = VideoCommand.fromBuffer(wrapper.data);
//     // sendMessage(command);  // Echo the request
//     // collection.parent.send(command, command.details.name);
//   }

// 	@override
// 	void onHeartbeat(Connect heartbeat, SocketInfo source) { }

// 	@override
// 	void updateSettings(UpdateSetting settings) { }

//   @override
//   void sendMessage(Message message, {SocketInfo? socketOverride}) {
//     final m = VideoData.fromBuffer(message.);
//     super.sendMessage(m);
//   }
// }
