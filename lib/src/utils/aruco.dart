import "dart:math";

import "package:burt_network/protobuf.dart";
import "package:dartcv4/dartcv.dart";
import "package:video/src/targeting/frame_properties.dart";

final _arucoDictionary = ArucoDictionary.predefined(PredefinedDictionaryType.DICT_4X4_50);
final _arucoParams = ArucoDetectorParameters.empty();
final _arucoDetector = ArucoDetector.create(_arucoDictionary, _arucoParams);
final _arucoColor = Scalar.fromRgb(0, 255, 0);

/// Detects and processes Aruco markers as a target message list, optionally draws them to the image
Future<List<TrackedTarget>> detectAndProcessMarkers(
  Mat matrix,
  FrameProperties frameProperties, {
  bool draw = true,
}) async {
  final (corners, ids, rejected) = await detectArucoMarkers(matrix, draw: draw);
  final detectedMarkers = <TrackedTarget>[];
  for (int i = 0; i < ids.length; i++) {
    var centerX = 0.0;
    var centerY = 0.0;
    for (final corner in corners[i]) {
      centerX += corner.x;
      centerY += corner.y;
    }
    centerX /= 4;
    centerY /= 4;

    final (:yaw, :pitch) = calculateYawPitch(frameProperties, centerX, centerY);

    final cornerVec = VecPoint.generate(
      corners[i].length,
      (idx) => Point(corners[i][idx].x.toInt(), corners[i][idx].y.toInt()),
    );
    final area = contourArea(cornerVec);

    cornerVec.dispose();

    detectedMarkers.add(
      TrackedTarget(
        detectionType: TargetDetectionType.ARUCO,
        tagId: ids[i],
        yaw: yaw,
        pitch: pitch,
        area: area,
        areaPercent: area / (matrix.width * matrix.height),
        centerX: centerX.toInt(),
        centerY: centerY.toInt(),
        corners: corners[i].expand((corner) sync* {
          yield corner.x.toInt();
          yield corner.y.toInt();
        }),
      ),
    );
  }
  corners.dispose();
  ids.dispose();
  rejected.dispose();
  return detectedMarkers;
}

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

/// Calculates the yaw and pitch of a coordinate in pixels using the undistorted center
/// and camera focal length
/// 
/// Math taken from FRC Team 254: https://www.team254.com/documents/vision-control/
({double yaw, double pitch}) calculateYawPitch(
  FrameProperties properties,
  double tagCenterX,
  double tagCenterY,
) {
  double centerX = tagCenterX;
  double centerY = tagCenterY;

  if (properties.calibrationData != null) {
    final centerVec = VecPoint2f.fromList([Point2f(tagCenterX, tagCenterY)]);
    final temp = Mat.fromVec(centerVec);
    final result = undistortPoints(
      temp,
      properties.calibrationData!.intrinsics!,
      properties.calibrationData!.distCoefficients!,
      criteria: (TERM_COUNT + TERM_EPS, 30, 1e-6),
    );
    final undistortedVec = result.at<Vec2f>(0, 0);

    // The output coordinates are normalized, see: https://stackoverflow.com/a/65861232
    if (undistortedVec.val1.isFinite) {
      centerX = undistortedVec.val1 * properties.focalLength + properties.centerX;
    }
    if (undistortedVec.val2.isFinite) {
      centerY = undistortedVec.val2 * properties.focalLength + properties.centerY;
    }

    centerVec.dispose();
    temp.dispose();
    result.dispose();
  }

  final yaw = atan((centerX - properties.centerX) / properties.focalLength);
  final pitch = atan((properties.centerY - centerY) / properties.focalLength);
  // final yaw = atan((tagCenterX - properties.centerX) / properties.horizontalFoV);
  // final pitch = atan((properties.centerY - tagCenterY) / (properties.horizontalFoV / cos(yaw)));

  return (yaw: yaw * (180 / pi), pitch: pitch * (180 / pi));
}
