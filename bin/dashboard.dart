import "dart:io";

import "package:burt_network/burt_network.dart";
import "package:burt_network/generated.dart";

final hearbeat = Connect(sender: Device.DASHBOARD, receiver: Device.VIDEO);
/*
class VideoServer extends ProtoSocket{

  VideoServer({required super.port}): super(device: Device.DASHBOARD, destination: SocketInfo(address: InternetAddress("127.0.0.1"), port: 8002));

  @override
  void onHeartbeat(Connect heartbeat, SocketInfo source) {
    // TODO: implement onHeartbeat
  }

  @override
  Future<void> checkHeartbeats() async{
    // TODO: implement checkHearbeats
    // Send a heartbeart message to each device connected
  }

  @override
  void onMessage(WrappedMessage wrapper) {
    if(wrapper.name == VideoData){
      final data = VideoData.fromBuffer(wrapper.data);
      if(!data.hasFrame()) return;
    }
    // TODO: implement onMessage
  }

  @override
  void updateSettings(UpdateSetting settings) {
    // TODO: implement updateSettings
  }
}
*/