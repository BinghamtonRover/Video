import "dart:ffi";

import "package:burt_network/burt_network.dart";
import "package:burt_network/logging.dart";
import "package:opencv_ffi/opencv_ffi.dart";
import "package:video/src/collection.dart";

/// Detect ArUco tags in the cv::aruco::DICT_4X4_50 dictionary and annotate them
/// Detect ArUco tags in the cv::aruco::DICT_4X4_50 dictionary and send relevant info to the parent isolate
VideoData detectAruco(Pointer<Mat> image, int resolutionWidth  ){
  final Pointer<ArucoMarkers> markers = detectArucoMarkers(image, dictionary: 0);
  /// Draws the markers on the image
  drawMarkers(image, markers);


  // logger.debug("count: ${markers.ref.count}");
  /// If a marker exists, send the data to the parent isolate
  if (markers.ref.count > 0){
    final x1 = markers.ref.markers.ref.lowerLeft_x;
    final y1 = markers.ref.markers.ref.lowerLeft_y;

    final x2 = markers.ref.markers.ref.upperRight_x;
    final y2 = markers.ref.markers.ref.upperRight_y;

    // Get the x midpoint for the horizontal position on the camera
    final midpointX = (x1+x2)/2;
    // get current size of the aruco (length * height)
    final arucoSize = (x2 - x1) * (y1 - y2);
    logger.info("x1: $x1");
    logger.info("x2: $x2");
    logger.info("y1: $y1");
    logger.info("y2: $y2");

    // new "0" on the number line
    final normailzedPositionX =  midpointX - (resolutionWidth/2);
    // -1 to 1, -1 is furthest left, 1 is furthest right
    final percentage = normailzedPositionX/(resolutionWidth/2);
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
