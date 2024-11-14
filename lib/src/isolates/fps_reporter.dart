import "dart:async";

import "package:burt_network/burt_network.dart";

mixin FpsReporter {
  CameraName get name;
  void sendLog(Level level, String message);

  Timer? _fpsTimer;

  /// How many FPS this camera is actually running at.
  int _fpsCount = 0;

  void startFps() {
    _fpsTimer = Timer.periodic(const Duration(seconds: 5), _printFps);
  }

  void stopFps() {
    _fpsTimer?.cancel();

  }

  void recordFrame() => _fpsCount++;

  void _printFps(Timer timer) {
    sendLog(LogLevel.trace, "Camera $name sent ${_fpsCount ~/ 5} frames");
    _fpsCount = 0;
  }
}
