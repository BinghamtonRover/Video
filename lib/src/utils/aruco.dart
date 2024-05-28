import "dart:ffi";

import "package:burt_network/burt_network.dart";
import "package:burt_network/logging.dart";
import "package:opencv_ffi/opencv_ffi.dart";
import "package:video/src/collection.dart";

/// Detect ArUco tags in the cv::aruco::DICT_4X4_50 dictionary and annotate them
void detectAndAnnotateFrames(Pointer<Mat> image) {
  final Pointer<ArucoMarkers> markers = detectArucoMarkers(image, dictionary: 0);
  drawMarkers(image, markers);
  markers.dispose();
}

void detectAndSendToAutonomy(Pointer<Mat> image){
  final Pointer<ArucoMarkers> markers = detectArucoMarkers(image, dictionary: 0);
  if (markers.ref.count != 0){
    final lowerLeft_X = markers.ref.markers.ref.lowerLeft_x;
    final lowerLeft_Y = markers.ref.markers.ref.lowerLeft_y;

    final lowerRight_X = markers.ref.markers.ref.lowerRight_x;
    final lowerRight_Y = markers.ref.markers.ref.lowerRight_y;

    final upperLeft_X = markers.ref.markers.ref.upperLeft_x;
    final upperLeft_Y = markers.ref.markers.ref.upperLeft_y;

    final upperRight_X = markers.ref.markers.ref.upperRight_x;
    final upperRight_Y = markers.ref.markers.ref.upperRight_y;
    // need to send to parent first
  }
}