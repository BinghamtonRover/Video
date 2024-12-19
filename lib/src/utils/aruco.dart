import "package:dartcv4/dartcv.dart";

final _arucoDictionary = ArucoDictionary.predefined(PredefinedDictionaryType.DICT_4X4_50);
final _arucoParams = ArucoDetectorParameters.empty();
final _arucoDetector = ArucoDetector.create(_arucoDictionary, _arucoParams);
final _arucoColor = Scalar.fromRgb(0, 255, 0);

/// Detect ArUco tags in the cv::aruco::DICT_4X4_50 dictionary and annotate them
Future<void> detectAndAnnotateFrames(Mat image) async {
  final (corners, ids, rejected) = await _arucoDetector.detectMarkersAsync(image);
  await arucoDrawDetectedMarkersAsync(image, corners, ids, _arucoColor);
  corners.dispose();
  ids.dispose();
  rejected.dispose();
}
