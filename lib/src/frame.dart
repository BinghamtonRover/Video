import "package:burt_network/burt_network.dart";


class FrameData {
  final CameraDetails details;
  final int address;
  final int length;

  FrameData({required this.details, required this.address, required this.length});
}