import "package:burt_network/burt_network.dart";

Map<String, CameraName> cameraNames = {
  "/dev/realsense_rgb": CameraName.ROVER_FRONT,
	"/dev/realsense_depth": CameraName.AUTONOMY_DEPTH,
	"/dev/subsystem1": CameraName.SUBSYSTEM1,
	"/dev/subsystem2": CameraName.SUBSYSTEM2,
	"/dev/subsystem3": CameraName.SUBSYSTEM3,
};

Map<int, CameraName> cameraIndexesWindows = {
  0: CameraName.ROVER_FRONT,
	1: CameraName.AUTONOMY_DEPTH,
	2: CameraName.SUBSYSTEM1,
	3: CameraName.SUBSYSTEM2,
	4: CameraName.SUBSYSTEM3,
};