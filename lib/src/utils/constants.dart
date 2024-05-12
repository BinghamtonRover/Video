import "package:burt_network/generated.dart";

/// These list maps OpenCV IDs (index) to [CameraName]s.
///
/// This is HIGHLY dependent on the EXACT order of the USB ports.
///
/// Map for MAC or LINUX devices
Map<CameraName, String> cameraNames = {
  CameraName.ROVER_FRONT: "/dev/realsense_rgb",
  CameraName.ROVER_REAR: "/dev/rear_camera",
  CameraName.AUTONOMY_DEPTH: "/dev/realsense_depth",
  CameraName.SUBSYSTEM1: "/dev/subsystem1",
  CameraName.SUBSYSTEM2: "/dev/subsystem2",
  CameraName.SUBSYSTEM3: "/dev/subsystem3",
};

/// Map for WINDOWS devices
Map<CameraName, int> cameraIndexes = {
  CameraName.ROVER_REAR: 0,
  CameraName.AUTONOMY_DEPTH: 4,
  CameraName.ROVER_FRONT: 5,
  CameraName.SUBSYSTEM1: 1,
  CameraName.SUBSYSTEM2: 2,
  CameraName.SUBSYSTEM3: 3,
};
