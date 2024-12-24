import "dart:math";

/// A class to store and calculate the capture intrinsics of a camera
/// Used mainly in target calculations for converting pixels to degrees
class FrameProperties {
  /// The width of the image being taken by the camera
  final int captureWidth;
  /// The height of the image being taken by the camera
  final int captureHeight;
  /// The diagonal field of view of the camera
  final double diagonalFoV;
  /// The x coordinate of the center point of the iamge
  late final double centerX;
  /// The y coordinate of the center point of the image
  late final double centerY;
  /// The horizontal focal length of the image frame
  late final double horizontalFocalLength;
  /// The vertical focal length of the image frame
  late final double verticalFocalLength;

  /// Constructor for frame properties, initializes capture resolutions, FOV,
  /// and determines the horizontal and vertical focal lengths
  FrameProperties({
    required this.captureWidth,
    required this.captureHeight,
    required this.diagonalFoV,
  }) {
    centerX = (captureWidth / 2.0) - 0.5;
    centerY = (captureHeight / 2.0) - 0.5;
    final (:horizontal, :vertical) = calculateFoV(diagonalFoV, captureWidth, captureHeight);
    horizontalFocalLength = horizontal;
    verticalFocalLength = vertical;
  }

  /// Determines the horizontal and vertical focal lengths of the camera based on the diagonal FOV and capture resolution
  ({double horizontal, double vertical}) calculateFoV(double diagonalFoV, int captureWidth, int captureHeight) {
    // Math taken from PhotonVision:
    // https://github.com/PhotonVision/photonvision/blob/5df189d306be89a80b14e6bee9e9df2c31f7f589/photon-core/src/main/java/org/photonvision/vision/frame/FrameStaticProperties.java#L127
    final diagonalRadians = diagonalFoV * (pi / 180);
    final diagonalAspect = sqrt(captureWidth * captureWidth + captureHeight + captureHeight);

    final horizontalView = atan(tan(diagonalRadians / 2) * (captureWidth / diagonalAspect)) * 2;
    final verticalView = atan(tan(diagonalRadians / 2) * (captureHeight / diagonalAspect)) * 2;

    return (horizontal: horizontalView * (180 / pi), vertical: verticalView * (180 / pi));
  }
}
