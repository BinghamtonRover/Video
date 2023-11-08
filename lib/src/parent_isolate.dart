import "dart:async";
import "dart:ffi";

import "package:opencv_ffi/opencv_ffi.dart";
import "package:typed_isolate/typed_isolate.dart";
import "package:burt_network/burt_network.dart";
import "package:video/src/collection.dart";
import "package:video/src/frame.dart";
import "package:video/src/functions.dart";

import "server.dart";

class VideoController extends IsolateParent<VideoCommand, FrameData>{

  @override
  Future<void> run() async {}

  @override onData(FrameData data){
    if(data.length != 0){
      print("recieved frame");
      final frame = OpenCVImage(pointer: Pointer.fromAddress(data.address), length: data.length);
      collection.videoServer.sendMessage(VideoData(frame: frame.data, details: data.details));
      frame.dispose();
    } else {
      print(data.details);
      collection.videoServer.sendMessage(VideoData(details: data.details));
    }
  }
}