import "package:burt_network/burt_network.dart";

/// These list maps OpenCV IDs (index) to [CameraName]s. 
/// 
/// This is HIGHLY dependent on the EXACT order of the USB ports.
/// 
/// Map for MAC or LINUX devices
Map<CameraName, String> cameraNames = {
  CameraName.ROVER_FRONT: "/dev/realsense_rgb",
  CameraName.ROVER_REAR: "...",
  CameraName.AUTONOMY_DEPTH: "/dev/realsense_depth",
  CameraName.SUBSYSTEM1: "/dev/subsystem1",
  CameraName.SUBSYSTEM2: "/dev/subsystem2",
  CameraName.SUBSYSTEM3: "/dev/subsystem3",
};

/// Map for WINDOWS devices
Map<CameraName, int> cameraIndexes = {
  CameraName.ROVER_FRONT: 0,
  CameraName.ROVER_REAR: 1, 
  CameraName.AUTONOMY_DEPTH: 1,
  CameraName.SUBSYSTEM1: 2,
  CameraName.SUBSYSTEM2: 3,
  CameraName.SUBSYSTEM3: 4,
};
