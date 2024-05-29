import "package:burt_network/generated.dart";

/// These list maps OpenCV IDs (index) to [CameraName]s.
///
/// This is HIGHLY dependent on the EXACT order of the USB ports.
///
/// Map for MAC or LINUX devices
Map<CameraName, String> cameraNames = {
  CameraName.ROVER_FRONT: "/dev/rover-cam_realsense_rgb",
  CameraName.ROVER_REAR: "/dev/rover-cam_subsystem_3",
  CameraName.AUTONOMY_DEPTH: "/dev/rover-cam_realsense_depth",
  CameraName.SUBSYSTEM1: "/dev/rover-cam_subsystem_1",
  CameraName.SUBSYSTEM2: "/dev/rover-cam_subsystem_2",
  CameraName.SUBSYSTEM3: "/dev/rover-cam_subsystem_3",
  CameraName.BOTTOM_LEFT: "/dev/rover-cam_bottom_left",
  CameraName.BOTTOM_RIGHT: "/dev/rover-cam_bottom_right",
};

/// Map for WINDOWS devices
/// Map for WINDOWS devices
Map<CameraName, int> cameraIndexes = {
  CameraName.ROVER_REAR: 1,
  CameraName.AUTONOMY_DEPTH: 0,
  CameraName.ROVER_FRONT: 2,
  CameraName.SUBSYSTEM1: 3,
  CameraName.SUBSYSTEM2: 4,
  CameraName.SUBSYSTEM3: 5,
  CameraName.BOTTOM_LEFT: 6,
  CameraName.BOTTOM_RIGHT: 7,
};
