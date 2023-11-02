import "package:burt_network/burt_network.dart";
import "package:video/src/functions.dart";

import 'parent_isolate.dart';
import "camera_isolates.dart";

void main() async {
  final parent = VideoController();
  final child = await parent.spawn(CameraIsolate(details: getDefaultDetails(CameraName.ROVER_FRONT)));
  await Future<void>.delayed(const Duration(seconds: 1));
  await parent.run();
  await Future<void>.delayed(const Duration(minutes: 1), () async {
    child.kill();
    await parent.dispose();
  });
  print("huh");
}