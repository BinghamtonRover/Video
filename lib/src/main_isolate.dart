import "dart:ffi";

import "package:opencv_ffi/opencv_ffi.dart";
import "package:typed_isolate/typed_isolate.dart";
import "package:burt_network/burt_network.dart";
import "package:video/src/functions.dart";

import "server.dart";

class CameraController extends IsolateParent<VideoCommand, List<int>>{
  final videoServer = VideoServer(port: 8002); 
  @override
  Future<void> run() async {
    await videoServer.init();
    //TODO: 
    send(VideoCommand(), CameraName.ROVER_FRONT);
  }

  @override onData(List<int> data){
    print("Received this: $data");
    final frame = OpenCVImage(pointer: Pointer.fromAddress(data[0]), length: data[1]);
    print("frame in bytes ${frame.data}");
    videoServer.sendMessage(VideoData(frame: frame.data, details: getDefaultDetails(CameraName.ROVER_FRONT)));
  }

  Future<void> dispose() async {
    await videoServer.dispose();
    close();
  }
}
