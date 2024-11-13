import "package:typed_isolate/typed_isolate.dart";
import "package:video/src/lidar/lidar.dart";

void main() async {
  // final server = RoverSocket(port: 8002, device: Device.VIDEO);
  // await server.init();

  final lidar = LidarFFI();
  await lidar.init();
  while (true) {
    await Future<void>.delayed(const Duration(seconds: 1));
  }
}

//   final cap = VideoCapture.fromDevice(0);
//   final params = VecI32.fromList([IMWRITE_JPEG_QUALITY, 50]);
//   final details = CameraDetails(name: CameraName.ROVER_FRONT, status: CameraStatus.CAMERA_ENABLED);
//   while (true) {
//     final (success, frame) = cap.read();
//     if (!success) continue;
//     final (success2, jpg) = imencode(".jpg", frame, params: params);
//     if (!success2) continue;
//     final message = VideoData(frame: jpg, details: details);
//     server.sendMessage(message);
//     await Future<void>.delayed(Duration(milliseconds: 16));
//   }
// }
