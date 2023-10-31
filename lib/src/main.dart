import "main_isolate.dart";
import "camera_isolates.dart";

void main() async {
  final parent = CameraController();
  final child = await parent.spawn(FrontIsolate());
  await Future<void>.delayed(const Duration(seconds: 1));
  await parent.run();
  await Future<void>.delayed(const Duration(minutes: 5), () async {
    child.kill();
    await parent.dispose();
  });
  print("huh");
}