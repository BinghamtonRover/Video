import "dart:math";

import "package:dartcv4/dartcv.dart";
import "package:video/src/targeting/frame_properties.dart";

final _arucoDictionary = ArucoDictionary.predefined(PredefinedDictionaryType.DICT_4X4_50);
final _arucoParams = ArucoDetectorParameters.empty();
final _arucoDetector = ArucoDetector.create(_arucoDictionary, _arucoParams);
final _arucoColor = Scalar.fromRgb(0, 255, 0);

/// Detect ArUco tags in the cv::aruco::DICT_4X4_50 dictionary
Future<(VecVecPoint2f, VecI32, VecVecPoint2f)> detectArucoMarkers(
  Mat image, {
  bool draw = true,
}) async {
  final (corners, ids, rejected) = await _arucoDetector.detectMarkersAsync(image);
  if (draw) {
    await arucoDrawDetectedMarkersAsync(image, corners, ids, _arucoColor);
  }
  return (corners, ids, rejected);
}

/// Detect ArUco tags in the cv::aruco::DICT_4X4_50 dictionary and annotate them
Future<void> detectAndAnnotateFrames(Mat image) async {
  final (corners, ids, rejected) = await _arucoDetector.detectMarkersAsync(image);
  await arucoDrawDetectedMarkersAsync(image, corners, ids, _arucoColor);
  corners.dispose();
  ids.dispose();
  rejected.dispose();
}

({double yaw, double pitch}) calculateYawPitch(
  FrameProperties properties,
  double tagCenterX,
  double tagCenterY,
) {
  final yaw = atan((tagCenterX - properties.centerX) / properties.horizontalFocalLength);
  final pitch = atan((properties.centerY - tagCenterY) / properties.verticalFocalLength);

  return (yaw: yaw * (180 / pi), pitch: pitch * (180 / pi));
}
