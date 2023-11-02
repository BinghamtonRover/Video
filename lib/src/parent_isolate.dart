import "dart:ffi";

import "package:opencv_ffi/opencv_ffi.dart";
import "package:typed_isolate/typed_isolate.dart";
import "package:burt_network/burt_network.dart";
import "package:video/src/frame.dart";
import "package:video/src/functions.dart";

import "server.dart";

class VideoController extends IsolateParent<VideoCommand, FrameData>{
  final videoServer = VideoServer(port: 8002); 
  @override
  Future<void> run() async {
    await videoServer.init();
    //TODO: 
    send(VideoCommand(), CameraName.ROVER_FRONT);
  }

  @override onData(FrameData data){
    if(data.length != 0){
      print("recieved frame");
      final frame = OpenCVImage(pointer: Pointer.fromAddress(data.address), length: data.length);
      videoServer.sendMessage(VideoData(frame: frame.data, details: data.details));
      frame.dispose();
    } else {
      print(data.details);
      videoServer.sendMessage(VideoData(details: data.details));
    }
  }

  Future<void> dispose() async {
    await videoServer.dispose();
    close();
  }
}
