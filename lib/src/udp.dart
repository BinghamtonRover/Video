import "package:burt_network/burt_network.dart";
import "collection.dart";

class VideoServer extends ServerSocket{
  VideoServer({required super.port}) : super(device: Device.VIDEO);

  @override
  void onMessage(WrappedMessage wrapper) {
    if(wrapper.name != VideoCommand().messageName){ // Can ignore message if not a video message
      return;
    }
    final command = VideoCommand.fromBuffer(wrapper.data);
    //command.id
  }
}
