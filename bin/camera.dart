// ignore_for_file: avoid_print

import "package:opencv_ffi/opencv_ffi.dart";

void main(List<String> args) async {
  final cameraName = args.first;
  final index = int.tryParse(cameraName);
  if (index == null) {
    print("Non-integer camera names are not yet supported");
    return;
  }

  final camera = Camera(index);
  print("Displaying camera $cameraName");
  print("Press Ctrl+C to quit");
  try {
    while (true) {
      camera.showFrame();
    }
  } finally {
    camera.dispose();    
  }
}
