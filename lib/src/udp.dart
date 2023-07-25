import "package:burt_network/burt_network.dart";
import "package:burt_network/generated.dart";

class VideoServer extends ServerSocket{
  VideoServer({required super.port}) : super(device: Device.VIDEO);

  @override
  void onMessage(WrappedMessage wrapper) {
    if(wrapper.name == VideoCommand().messageName){

    }
    final command = VideoCommand.fromBuffer(wrapper.data);
  }
}
