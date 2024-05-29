import "dart:ffi";
// import "dart:collection";
import "dart:async";

import "package:burt_network/generated.dart";
import "package:burt_network/logging.dart";
import "package:protobuf/protobuf.dart";
import "package:opencv_ffi/opencv_ffi.dart";

import "package:video/video.dart";

extension on CameraDetails {
  bool get interferesWithAutonomy => hasResolutionHeight()
    || hasResolutionWidth()
    || hasFps()
    || hasStatus();
}

/// An isolate to read RGB, depth, and colorized frames from the RealSense. 
/// 
/// While using the RealSense SDK for depth streaming, OpenCV cannot access the standard RGB frames,
/// so it is necessary for this isolate to grab the RGB frames as well.
/// 
/// Since the RealSense is being used for autonomy, certain settings that could interfere with the
/// autonomy program are not allowed to be changed, even for the RGB camera.
class RealSenseIsolate extends CameraIsolate {
  /// The native RealSense object. MUST be `late` so it isn't initialized on the parent isolate.
  late final RealSenseInterface camera = RealSenseInterface.forPlatform();
  /// Creates an isolate to read from the RealSense camera.
  RealSenseIsolate({required super.details});

  @override
  void onData(VideoCommand data) {
    if (data.details.interferesWithAutonomy) {
      sendLog(LogLevel.error, "That would break autonomy");
    } else {
      super.onData(data);
    }
  }

  @override
  void initCamera() {
    if (!camera.init()) {
      final details = CameraDetails(status: CameraStatus.CAMERA_DISCONNECTED);
      updateDetails(details);
      return sendLog(LogLevel.warning, "Could not open RealSense");
    }
    sendLog(LogLevel.debug, "RealSense connected");
    final name = camera.getName();
    sendLog(LogLevel.trace, "RealSense model: $name");
    if (!camera.startStream()) {
      final details = CameraDetails(status: CameraStatus.CAMERA_NOT_RESPONDING);
      updateDetails(details);
      return sendLog(LogLevel.warning, "Could not start RealSense");
    }
    sendLog(LogLevel.debug, "Started streaming from RealSense");
  }

  @override
  void disposeCamera() {
    camera.stopStream();
    camera.dispose();
  }

  @override
  Future<void> sendFrames() async {
    // Get frames from RealSense
    final frames = camera.getFrames();
    if (frames == nullptr) return;

    // Compress colorized frame
    final Pointer<Uint8> rawColorized = frames.ref.colorized_data;
    final Pointer<Mat> colorizedMatrix = getMatrix(camera.depthResolution.height, camera.depthResolution.width, rawColorized);
    final OpenCVImage? colorizedJpg = encodeJpg(colorizedMatrix, quality: details.quality);
    if (colorizedJpg == null) {
      sendLog(LogLevel.debug, "Could not encode colorized frame"); 
    } else {
      sendFrame(colorizedJpg);
    }

    if(frames.ref.depth_data != nullptr && !frames.ref.depth_length.isOdd){
      //print("width: ${camera.depthResolution.width}, height: ${camera.depthResolution.height}");
      // final depthAvgs = 
      compressDepthFrame(frames.ref.depth_data.cast<Uint16>(), 100, 100);
    }
    //findObstacles(depthAvgs);
    //printMatrix(depthAvgs);
    sendRgbFrame(frames.ref.rgb_data);
    fpsCount++;
    // send(DepthFramePayload(frames.address));  // For autonomy
    nativeLib.Mat_destroy(colorizedMatrix);
    frames.dispose();
  }

  /// Sends the RealSense's RGB frame and optionally detects ArUco tags.
  void sendRgbFrame(Pointer<Uint8> rawRGB) {
    if (rawRGB == nullptr) return;
    final Pointer<Mat> rgbMatrix = getMatrix(camera.rgbResolution.height, camera.rgbResolution.width, rawRGB);
    //detectAndAnnotateFrames(rgbMatrix);  // detect ArUco tags

    // Compress the RGB frame into a JPG
    if (rgbMatrix != nullptr) {
      final OpenCVImage? rgbJpg = encodeJpg(rgbMatrix, quality: details.quality);
      if (rgbJpg == null) {
        sendLog(LogLevel.debug, "Could not encode RGB frame"); 
      } else {
        final newDetails = details.deepCopy()..name = CameraName.ROVER_FRONT;
        sendFrame(rgbJpg, detailsOverride: newDetails);
      }
      nativeLib.Mat_destroy(rgbMatrix);
    }
  }

  /// Returns a compressed 2D array from depthFrame with a new width and height
  /// Divides the [depthFrame] into [newWidth] by [newHeight] boxes and then calculates the average of each box. 
  /// Each item in nested list is an average of the box
  List<List<double>> compressDepthFrame(Pointer<Uint16> depthFrame, int newWidth, int newHeight){
    /*
    depthFrame is a 1D array with length camera.depthResolution.height * camera.depthResolution.width
    depthFrame[row*camera.depthResolution.width + column] = matrix[row][column] 
    1. Turn DepthFrame to 2D Matrix
    2. break it up into a gride of newWidth * newHeight
    Each box will be (camera.depthResolution.height / newHeight) * (camera.depthResolution.width / newWidth)
    */
    double sum = 0; 
    final matrix = <List<double>>[];
    final boxHeight = camera.depthResolution.height ~/ newHeight;
    final boxWidth = camera.depthResolution.width ~/ newWidth;
    //print("With given dimensions only ${boxWidth*newWidth} x ${boxHeight*newHeight} will be analyzed");
    final boxSize = boxWidth * boxHeight;
    int count = 1;
    // int obstacles = 0;
    // int missingBoxes = 0;
    // int foundBoxes = 0;
    bool left = false;
    bool center = false;
    bool right = false;
    //bool bottom = false;

    /// 640 by 480 = 307200
    for(int row = 0; row < (boxHeight*newHeight); row += boxHeight){
      final mRow = <double>[];
      for(int column = 0; column < (boxWidth*newWidth); column += boxWidth){
        /// Calculate the average of a box with width [boxWidth] and height [boxHeight]
        //print("before box ${(row) * camera.depthResolution.width + (column)}");
        for(int i = 0; i < boxHeight; i++){
          for(int j = 0; j < boxWidth; j++){
            if(depthFrame[(row + i) * camera.depthResolution.width + (column + j)] != 0){
              count++;
              sum += depthFrame[(row + i) * camera.depthResolution.width + (column + j)];
            }
          }
        }
        //print("after box");
        if(count > (boxSize * 0.5)) {
          // foundBoxes++;
          mRow.add(sum / count);
          if((sum / count) < 2000){
            // obstacles++;
            // print("($column, $row)");
            //if(row > (camera.depthResolution.height ~/ 2)){
              //bottom = true;
            //} else 
            if(column < (camera.depthResolution.width ~/ 3)){
              left = true;
            } else if(column < (2 * camera.depthResolution.width ~/ 3)){
              center = true;
            } else if(column > (2 * camera.depthResolution.width ~/ 3)){
              right = true;
            }  
          }
        } else {
          //missingBoxes++;
          mRow.add(-1);
        }
        count = 1;
        sum = 0;
      }
      matrix.add(mRow);
    }
    // print("$missingBoxes missing Boxes, $foundBoxes found boxes");
    // print("Found ${obstacles} obstacles");
    // print("$bottom bottom obstacle");
    // print("$left top left obstacle");
    // print("$center top center obstacle");
    // print("$right top right obstacle");
    final data = VideoData(
      leftObstacle: left ? BoolState.YES : BoolState.NO,
      centerObstacle: center ? BoolState.YES : BoolState.NO,
      rightObstacle: right ? BoolState.YES : BoolState.NO,
    );
    send(AutonomyPayload(data));
    return matrix;
  }

  // void printMatrix(List<List<double>> depthAvgs){
  //   final buffer = StringBuffer();
  //   for(final row in depthAvgs){
  //     for(final column in row){
  //       buffer.write((column.toString() + "    ").substring(0, 5));
  //       buffer.write(" ");
  //     }
  //     print(buffer);
  //     buffer.clear();
  //   }
  // }

  // void findObstacles(List<List<double>> depths){
  //   final height = depths.length;
  //   final width = depths[0].length;

  //   final visited = <List<bool>>[];
  //   for(final row in depths){
  //     visited.add(List.filled(row.length, false));
  //   }

  //   final horizon = height ~/ 2;
  //   //findHorizon(depths, width ~/ 2, height);
  //   /// Find if depth changes more than !!!!! 0.5 Meters !!!!!

  //   /// Bottom section everything beneath horizon 
  //   /// Start from (XMiddle, HorizonY)
    
  //   var y = 25;
  //   var x = 15;
  //   //left
  //   if(bfsUntilDepthChange(visited, depths, x, y, 2000, 0, 15, 0, 25)){
  //     print("Problem on Left");
  //   }
  //   y = 25;
  //   x = 25;
  //   if(bfsUntilDepthChange(visited, depths, x, y, 2000, 35, 50, 0, 25)){
  //     print("Problem on Middle");
  //   }
  //   y = 25;
  //   x = 35;
  //   if(bfsUntilDepthChange(visited, depths, x, y, 2000, 15, 35, 0, 25)){
  //     print("Problem on Right");
  //   }
  //   y = 25;
  //   x = 25;
  //   if(bfsUntilDepthChange(visited, depths, x, y, 2000, 0, 50, 25, 50)){
  //     print("Problem on Bottom");
  //   }
  // }

  // /// Function to perform BFS on given region
  // bool bfsUntilDepthChange(List<List<bool>> visited, List<List<double>> matrix, int x, int y, int depthChange, int left, int right, int top, int bottom) {
  //   final directions = [
  //     [-1, -1], [-1, 0], [-1, 1],
  //     [0, -1],         [0, 1],
  //     [1, -1], [1, 0], [1, 1],
  //   ];

  //   int newX;
  //   int newY;

  //   final Q = Queue<List<int>>(); 
  //   visited[y][x] = true;
  //   Q.add([x,y]);
  //   while(Q.isNotEmpty){   
  //     final coordinates = Q.removeFirst();
  //     for (final direction in directions) {
  //       newX = coordinates[0] + direction[0];
  //       newY = coordinates[1] + direction[1];

  //       if (newY >= top && newY < bottom && newX >= left && newX < right) {
  //         if(visited[newY][newX] != true && matrix[newY][newX] != -1){
  //           if((matrix[coordinates[1]][coordinates[0]] - matrix[newY][newX]).abs() > depthChange){
  //             print("The coordinates are (${coordinates[0]}, ${coordinates[1]}");
  //             return true;
  //           }
  //         }
  //         matrix[newY][newX] = -1;
  //         Q.add([newX,newY]);
  //       }
  //     }
  //   }
  //   return false;
  // }


  // int findHorizon(List<List<double>> depths, int middleX, int rows) => rows ~/ 2;
    /// Miniumum to consider it a horizon 
    // {double delta = 2;
    // int horizonY = -1;
    // for(var row = rows; row > 0; row--){
    //   if((depths[row][middleX] - depths[row - 1][middleX]).abs() > delta){
    //     delta = (depths[row][middleX] - depths[row - 1][middleX]).abs();
    //     horizonY = row;
    //   }
    // }
    // return horizonY; }
}
