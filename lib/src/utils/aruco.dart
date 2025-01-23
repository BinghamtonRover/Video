import "dart:math";

import "package:burt_network/protobuf.dart";
import "package:dartcv4/dartcv.dart";
import "package:video/src/targeting/frame_properties.dart";

final _arucoDictionary = ArucoDictionary.predefined(PredefinedDictionaryType.DICT_4X4_50);
final _arucoParams = ArucoDetectorParameters.empty();
final _arucoDetector = ArucoDetector.create(_arucoDictionary, _arucoParams);
final _arucoColor = Scalar.fromRgb(0, 255, 0);

/// The raw 3d output from opencv solvepnp
typedef ArucoRaw3DResult = ({int rval, VecMat rvecs, VecMat tvecs, Mat reprojectionError});

/// Utility methods for raw 3d solvepnp outputs
extension ArucoRaw3DUtil on ArucoRaw3DResult {
  /// Disposes all native resources used by the result objects
  void dispose() {
    rvecs.dispose();
    tvecs.dispose();
    reprojectionError.dispose();
  }
}

/// The size of the aruco marker in meters
const double markerSize = 6.0 / 39.37; //20.0 / 100;

final _objectPoints = Mat.fromVec(
      VecPoint3f.fromList([
        Point3f(-markerSize / 2, markerSize / 2, 0),
        Point3f(markerSize / 2, markerSize / 2, 0),
        Point3f(markerSize / 2, -markerSize / 2, 0),
        Point3f(-markerSize / 2, -markerSize / 2, 0),
      ]),
      rows: 4,
      cols: 1,
      type: MatType.CV_32FC3,
    );

/// Detects and processes Aruco markers as a target message list, optionally draws them to the image
Future<List<TrackedTarget>> detectAndProcessMarkers(
  Mat image,
  FrameProperties frameProperties, {
  bool draw = true,
}) async {
  final (corners, ids, rejected) = await _arucoDetector.detectMarkersAsync(image);

  if (draw) {
    await arucoDrawDetectedMarkersAsync(image, corners, ids, _arucoColor);
  }

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

    final pnpResult = calculate3DPose(frameProperties, corners[i]);
    Pose3d? bestCameraToTarget;
    double? bestReprojectionError;

    if (pnpResult != null) {
      final bestTranslation = pnpResult.tvecs[0].at<Vec3d>(0, 0);
      final bestRotation = pnpResult.rvecs[0].at<Vec3d>(0, 0);

      bestCameraToTarget = Pose3d(
        translation: Coordinates(
          x: bestTranslation.val1,
          y: -bestTranslation.val2,
          z: bestTranslation.val3,
        ),
        rotation: Orientation(
          x: bestRotation.val1 * (180 / pi),
          y: bestRotation.val2 * (180 / pi),
          z: bestRotation.val3 * (180 / pi),
        ),
      );
      bestReprojectionError = pnpResult.reprojectionError.at<double>(0, 0);

      drawFrameAxes(
        image,
        frameProperties.calibrationData!.intrinsics!,
        frameProperties.calibrationData!.distCoefficients!,
        pnpResult.rvecs[0],
        pnpResult.tvecs[0],
        markerSize,
      );
    }

    final cornerVec = VecPoint.generate(
      corners[i].length,
      (idx) => Point(corners[i][idx].x.toInt(), corners[i][idx].y.toInt()),
    );
    final area = contourArea(cornerVec);

    cornerVec.dispose();

    Aruco3DTargetResult? pnpResultProto;
    if (bestCameraToTarget != null) {
      pnpResultProto = Aruco3DTargetResult(
        bestCameraToTarget: bestCameraToTarget,
        bestReprojectionError: bestReprojectionError,
      );
    }

    detectedMarkers.add(
      TrackedTarget(
        detectionType: TargetDetectionType.ARUCO,
        tagId: ids[i],
        yaw: yaw,
        pitch: pitch,
        area: area,
        areaPercent: area / (image.width * image.height),
        centerX: centerX.toInt(),
        centerY: centerY.toInt(),
        corners: corners[i].expand((corner) sync* {
          yield corner.x.toInt();
          yield corner.y.toInt();
        }),
        pnpResult: pnpResultProto,
      ),
    );

    pnpResult?.dispose();
  }
  corners.dispose();
  ids.dispose();
  rejected.dispose();
  return detectedMarkers;
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

/// Calculates the 3D pose from the frame properties and target corners
/// 
/// If the frame properties does not contain a calibration, this will return null
ArucoRaw3DResult? calculate3DPose(FrameProperties properties, VecPoint2f corners) {
  if (properties.calibrationData == null) {
    return null;
  }

  final (rval, rvecs, tvecs, reprojectionError) = solvePnPGeneric(
    _objectPoints,
    Mat.fromVec(corners),
    properties.calibrationData!.intrinsics!,
    properties.calibrationData!.distCoefficients!,
    flags: SOLVEPNP_IPPE_SQUARE,
  );

  return (rval: rval, rvecs: rvecs, tvecs: tvecs, reprojectionError: reprojectionError);
}
