import "dart:math";

import "package:burt_network/protobuf.dart";

/// A class to store and calculate the capture intrinsics of a camera
/// Used mainly in target calculations for converting pixels to degrees
class FrameProperties {
  /// The width of the image being taken by the camera
  final int captureWidth;
  /// The height of the image being taken by the camera
  final int captureHeight;
  /// The diagonal field of view of the camera
  late final double diagonalFoV;
  /// The x coordinate of the center point of the iamge
  late final double centerX;
  /// The y coordinate of the center point of the image
  late final double centerY;
  /// The focal length of the camera
  late final double focalLength;
  /// The horizontal focal length of the image frame
  late final double horizontalFoV;
  /// The vertical focal length of the image frame
  late final double verticalFoV;

  /// Constructor for frame properties where the horizontal and focal FoV are known
  /// 
  /// Initializes capture resolutions, fov, and calculates the horizontal and vertical focal lengths
  FrameProperties({
    required this.captureWidth,
    required this.captureHeight,
    required this.horizontalFoV,
    required this.verticalFoV,
  }) {
    centerX = (captureWidth / 2.0) - 0.5;
    centerY = (captureHeight / 2.0) - 0.5;
    final aspectDiag = sqrt(captureWidth * captureWidth + captureHeight * captureHeight);
    diagonalFoV = atan(tan(horizontalFoV / 2) * (aspectDiag / captureWidth)) * 2 * (180 / pi);
    focalLength = captureWidth / (2 * tan(horizontalFoV / 2));
    print(horizontalFoV);
    print(verticalFoV);
    print(diagonalFoV);
    print(focalLength);
  }

  /// Constructor for frame properties, initializes capture resolutions, FOV,
  /// and determines the horizontal and vertical focal lengths
  FrameProperties.fromDiagonalFoV({
    required this.captureWidth,
    required this.captureHeight,
    required this.diagonalFoV,
  }) {
    centerX = (captureWidth / 2.0) - 0.5;
    centerY = (captureHeight / 2.0) - 0.5;
    final (:horizontal, :vertical, :focal) = calculateFoV(diagonalFoV, captureWidth, captureHeight);
    horizontalFoV = horizontal;
    verticalFoV = vertical;
    focalLength = focal;
  }

  /// A factory constructor for frame properties which initializes the camera settings based on the camera details
  /// 
  /// If the details has a horizontal and vertical fov, then it will initialize
  /// based on the horizontal and vertical fov, otherwise, it will assume the
  /// details have a diagonal fov
  factory FrameProperties.fromFrameDetails({required int captureWidth, required int captureHeight, required CameraDetails details}) {
    if (details.hasHorizontalFov() && details.hasVerticalFov()) {
      return FrameProperties(
        captureWidth: captureWidth,
        captureHeight: captureHeight,
        horizontalFoV: details.horizontalFov,
        verticalFoV: details.verticalFov,
      );
    }

    return FrameProperties.fromDiagonalFoV(
      captureWidth: captureWidth,
      captureHeight: captureHeight,
      diagonalFoV: details.diagonalFov,
    );
  }

  /// Determines the horizontal and vertical focal lengths of the camera based on the diagonal FOV and capture resolution
  ({double horizontal, double vertical, double focal}) calculateFoV(double diagonalFoV, int captureWidth, int captureHeight) {
    // Math taken from PhotonVision:
    // https://github.com/PhotonVision/photonvision/blob/5df189d306be89a80b14e6bee9e9df2c31f7f589/photon-core/src/main/java/org/photonvision/vision/frame/FrameStaticProperties.java#L127
    final diagonalRadians = diagonalFoV * (pi / 180);
    final diagonalAspect = sqrt(captureWidth * captureWidth + captureHeight * captureHeight);

    final horizontalView = atan(tan(diagonalRadians / 2) * (captureWidth / diagonalAspect)) * 2;
    final verticalView = atan(tan(diagonalRadians / 2) * (captureHeight / diagonalAspect)) * 2;
    final focalLength = captureWidth / (2 * tan(horizontalView / 2));

    return (horizontal: horizontalView * (180 / pi), vertical: verticalView * (180 / pi), focal: focalLength);
  }
}
