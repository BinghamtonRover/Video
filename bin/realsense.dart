import "package:video/video.dart";
import "package:burt_network/logging.dart";

final logger = BurtLogger();

class RealSense {
  final device = nativeLib.RealSense_create();
  
  Future<void> init() async {
    nativeLib.RealSense_init(device);
  }

  Future<void> dispose() async {
    nativeLib.RealSense_free(device);
  }

  Future<List<double>> getDepthFrame() async { 
    int width = nativeLib.RealSense_getWidth(device);
    int height = nativeLib.RealSense_getHeight(device);
    final frame = nativeLib.RealSense_getDepthFrame(device);
    List<double> newFrame = <double>[];
    for(int i = 0; i < width * height; i++){
      newFrame.add(frame.data);
      depth_frame_data = Pointer.fromAddress(depth_frame_data.address + 2);
    }         
    // TODO: Use this somehow ^
    return newFrame;
  }
}

void main() async {
  final realsense = RealSense();
  await realsense.init();
  logger.info("RealSense initialized");
  final frame = getDepthFrame();
  print(frame);
  await realsense.dispose();
  logger.info("RealSense disposed");
}
