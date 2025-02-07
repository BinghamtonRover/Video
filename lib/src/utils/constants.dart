import "dart:io";

import "package:burt_network/protobuf.dart";
import "package:dartcv4/dartcv.dart";

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
};

/// Map for WINDOWS devices
Map<CameraName, int> cameraIndexes = {
  CameraName.ROVER_REAR: 0,
  CameraName.AUTONOMY_DEPTH: 4,
  CameraName.ROVER_FRONT: 5,
  CameraName.SUBSYSTEM1: 10,
  CameraName.SUBSYSTEM2: 2,
  CameraName.SUBSYSTEM3: 3,
  CameraName.BOTTOM_LEFT: 6,
  CameraName.BOTTOM_RIGHT: 7,
};

/// Frames from this camera will be send to the vision program for further analysis.
const findObjectsInCameraFeed = CameraName.ROVER_FRONT;

/// Returns the camera depending on device program is running
///
/// Uses [cameraNames] or [cameraIndexes]
VideoCapture getCamera(CameraName name) => Platform.isWindows
  ? VideoCapture.fromDevice(cameraIndexes[name]!)
  : VideoCapture.fromFile(cameraNames[name]!);

/// Default details for a camera
///
/// Used when first creating the camera objects
CameraDetails getDefaultDetails(CameraName name) => CameraDetails(
  name: name,
  resolutionWidth: 600,
  resolutionHeight: 600,
  quality: 75,
  fps: 24,
  status: CameraStatus.CAMERA_ENABLED,
);

/// Default details for the RealSense camera.
///
/// These settings are balanced between autonomy depth and normal RGB.
CameraDetails getRealsenseDetails(CameraName name) => CameraDetails(
  name: name,
  resolutionWidth: 300,
  resolutionHeight: 300,
  quality: 50,
  fps: 0,
  status: CameraStatus.CAMERA_ENABLED,
);
