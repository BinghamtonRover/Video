// ignore_for_file: avoid_print

import "dart:ffi";
import "dart:typed_data";

import "package:opencv_ffi/opencv_ffi.dart";
import "package:typed_isolate/typed_isolate.dart";
import "package:burt_network/burt_network.dart";
import "functions.dart";

class FrontIsolate extends IsolateChild<List<int>, VideoCommand>{
  ///
  FrontIsolate() : super(id: CameraName.ROVER_FRONT);
  @override
  Future<void> run() async{
    print("here");
    //send([0, 1, 2, 3]);
    final camera = getCamera(CameraName.ROVER_FRONT);
    for(int i = 0; i < 10; i++){ //TRY THIS 10x
      final frame = camera.getJpg();
      if (frame != null){
        //send([frame.pointer.address, frame.data.length]);
        print("${frame.pointer.address}");
        final newframe = OpenCVImage(pointer: Pointer.fromAddress(frame.pointer.address), length: frame.data.length);
        print("Wait");
        //print("New Frame ${frame.data}");
        if(frame.data[45] == newframe.data[45]){
          print("Frames are the same");
        } else {
          print("How in the hell are they different");
        }
        frame.dispose();
        //newframe.dispose();
      }
      await Future.delayed(const Duration(seconds: 3));
    }

    /*
      if(frame != null){
        send([frame.pointer.address, frame.data.length]);
      } else {
        print("why is the frame null?");
      }
      */
  }

  @override
  void onData(VideoCommand data){
    //TODO
  }
}
