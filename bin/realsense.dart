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
    final frame = nativeLib.RealSense_getDepthFrame(device);
    // TODO: Use this somehow ^
    return [];
  }
}

void main() async {
  final realsense = RealSense();
  await realsense.init();
  logger.info("RealSense initialized");
  await realsense.dispose();
  logger.info("RealSense disposed");
}
