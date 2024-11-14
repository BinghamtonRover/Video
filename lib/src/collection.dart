import "dart:async";

import "package:burt_network/burt_network.dart";

import "package:video/video.dart";

/// Class to contain all video devices
class Collection extends Service {
  /// The [RoverSocket] to send messages through
  late final videoServer = RoverSocket(port: 8002, device: Device.VIDEO, collection: this);

  /// Main parent isolate
  final parent = VideoController();

  /// Function to initialize cameras
  @override
  Future<bool> init() async {
    logger..trace("Running in trace mode")..debug("Running in debug mode");
    await parent.init();
    await videoServer.init();
    logger.info("Video program initialized");
    return true;
  }

  /// Stops all cameras and disconnects from the hardware.
  @override
  Future<void> dispose() async {
    parent.stopAll();
    await parent.dispose();
    await videoServer.dispose();
  }

  /// Restarts the video program.
  Future<void> restart() async {
    await dispose();
    await init();
  }
}

/// Holds all the devices connected
final collection = Collection();

/// Displays logs in the terminal and sends them to the Dashboard
final logger = BurtLogger(socket: collection.videoServer);
