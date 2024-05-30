import "dart:ffi";

import "package:burt_network/burt_network.dart";
import "package:opencv_ffi/opencv_ffi.dart";

/// Detect ArUco tags in the cv::aruco::DICT_4X4_50 dictionary and send relevant info to the parent isolate
VideoData detectAndSendToAutonomy(Pointer<Mat> image, int resolutionWidth  ){
  final Pointer<ArucoMarkers> markers = detectArucoMarkers(image, dictionary: 0);
  /// Draws the markers on the image
  drawMarkers(image, markers);

  // logger.debug("count: ${markers.ref.count}");
  /// If a marker exists, send the data to the parent isolate
  if (markers.ref.count > 0){
    final x1 = markers.ref.markers.ref.lowerLeft_x;
    final x2 = markers.ref.markers.ref.upperRight_x;

    // Get the x midpoint for the horizontal position on the camera
    final midpointX = (x1+x2)/2;
    final arucoSize = (x2 - x1).abs() / resolutionWidth;

    // logger.info("resolutionWidth: $resolutionWidth");
    final normalizedPositionX = midpointX - (resolutionWidth / 2.0);
    // logger.debug("Normalized Position X: $normalizedPositionX");
    // logger.debug("Resolution Width: $resolutionWidth");

    // -1 to 1, -1 is furthest left, 1 is furthest right
    // Calculate normalized position directly
    final percentage = normalizedPositionX / (resolutionWidth / 2.0);
    // result[3] = percentage;
    // BoolState.YES is an alias for ON
    final data = VideoData(arucoDetected: BoolState.YES, arucoPosition: percentage, arucoSize: arucoSize);
    markers.dispose();
    return data;

  } else {
    final data = VideoData(arucoDetected: BoolState.NO);

    markers.dispose();
    return data;
  }
}
