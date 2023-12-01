// ignore_for_file: non_constant_identifier_names, avoid_print, prefer_final_locals, cascade_invocations, constant_identifier_names

import "package:video/video.dart";
import "package:ffi/ffi.dart";
import "dart:io";
import "dart:ffi";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                     These parameters are reconfigurable                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
const STREAM = rs2_stream.RS2_STREAM_DEPTH; // rs2_stream is a types of data provided by RealSense device           //
const FORMAT = rs2_format.RS2_FORMAT_Z16;   // rs2_format identifies how binary data is encoded within a frame      //
const WIDTH = 640;                          // Defines the number of columns for each frame or zero for auto resolve//
const HEIGHT = 0;                           // Defines the number of lines for each frame or zero for auto resolve  //
const FPS = 30;                             // Defines the rate of frames per second                                //
const STREAM_INDEX = 0;                     // Defines the stream index, used for multiple streams of the same type //
const HEIGHT_RATIO = 20;                    // Defines the height ratio between the original frame to the new frame //
const WIDTH_RATIO = 10;                     // Defines the width ratio between the original frame to the new frame  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

final arena = Arena();

/// Function calls to librealsense may raise errors of type rs_error*/
void checkError(Pointer<rs2_error> e) {
  if (e != nullptr) {
    print("rs_error was raised when calling ${nativeLib.rs2_get_failed_function(e)}(${nativeLib.rs2_get_failed_args(e)})");
    print("    ${nativeLib.rs2_get_error_message(e)}");
    exit(0);
  }
}

double get_depth_unit_value(Pointer<rs2_device> dev){
  final ePtr = arena<Pointer<rs2_error>>();
  Pointer<rs2_sensor_list> sensor_list = nativeLib.rs2_query_sensors(dev, ePtr);
  checkError(ePtr.value);

  int num_of_sensors = nativeLib.rs2_get_sensors_count(sensor_list, ePtr);
  checkError(ePtr.value);

  double depth_scale = 0;
  int is_depth_sensor_found = 0;   
  for(int i = 0; i < num_of_sensors; ++i){
    Pointer<rs2_sensor> sensor = nativeLib.rs2_create_sensor(sensor_list, i, ePtr);
    checkError(ePtr.value);

    // Check if the given sensor can be extended to depth sensor interface
    is_depth_sensor_found = nativeLib.rs2_is_sensor_extendable_to(sensor, rs2_extension.RS2_EXTENSION_DEPTH_SENSOR, ePtr);
    checkError(ePtr.value);

    if(1 == is_depth_sensor_found){
      depth_scale = nativeLib.rs2_get_option(sensor.cast(), rs2_option.RS2_OPTION_DEPTH_UNITS, ePtr);
      checkError(ePtr.value);
      nativeLib.rs2_delete_sensor(sensor);
      break;
    }
  }
  nativeLib.rs2_delete_sensor_list(sensor_list);

  if(0 == is_depth_sensor_found){
    print("Depth sensor not found!");
    exit(0);
  }
  arena.free(ePtr);
  return depth_scale;
}
void main() {
  final errorPtr = arena<Pointer<rs2_error>>();
  
  /// Create a context object. This object owns the handles to all connected realsense devices.
  final Pointer<rs2_context> context = nativeLib.rs2_create_context(RS2_API_VERSION, errorPtr);
  checkError(errorPtr.value);

  /// Get a list of all the connected devices.
  final Pointer<rs2_device_list> device_list = nativeLib.rs2_query_devices(context, errorPtr);
  checkError(errorPtr.value);

  final int dev_count = nativeLib.rs2_get_device_count(device_list, errorPtr);
  checkError(errorPtr.value);
  print("There are $dev_count connected RealSense devices.");
  if (0 == dev_count){return;}

  /// Get the first connected device
  final Pointer<rs2_device> dev = nativeLib.rs2_create_device(device_list, 0, errorPtr);
  checkError(errorPtr.value);

  final one_meter = 1.0 / get_depth_unit_value(dev);

  /// Create a pipeline to configure, start and stop camera streaming
  final Pointer<rs2_pipeline> pipeline =  nativeLib.rs2_create_pipeline(context, errorPtr);
  checkError(errorPtr.value);

  /// Create a config instance, used to specify hardware configuration
  Pointer<rs2_config> config = nativeLib.rs2_create_config(errorPtr);
  checkError(errorPtr.value);

  /// Request a specific configuration
  /// Parameters are reconfigurable
  nativeLib.rs2_config_enable_stream(config, STREAM, STREAM_INDEX, WIDTH, HEIGHT, FORMAT, FPS, errorPtr);
  checkError(errorPtr.value);

  // Start the pipeline streaming
  final Pointer<rs2_pipeline_profile> pipeline_profile = nativeLib.rs2_pipeline_start_with_config(pipeline, config, errorPtr);
  if (errorPtr.value != nullptr){
    print("The connected device doesn't support depth streaming!");
    exit(0);
  }

  final Pointer<rs2_stream_profile_list> stream_profile_list = nativeLib.rs2_pipeline_profile_get_streams(pipeline_profile, errorPtr);
  if(errorPtr.value != nullptr){
    print("Failed to create stream profile list!");
    exit(0);
  }

  final Pointer<rs2_stream_profile> stream_profile = nativeLib.rs2_get_stream_profile(stream_profile_list, 0, errorPtr);
  if (errorPtr.value != nullptr){
    print("Failed to create stream profile!");
    exit(0);
  }

  final Pointer<Int32> stream = arena.allocate<Int32>(4); 
  final Pointer<Int32> format = arena.allocate<Int32>(4);
  final Pointer<Int> index = arena.allocate<Int>(4); 
  final Pointer<Int> unique_id = arena.allocate<Int>(4);
  final Pointer<Int> framerate = arena.allocate<Int>(4);
  nativeLib.rs2_get_stream_profile_data(stream_profile, stream, format, index, unique_id, framerate, errorPtr);
  if(errorPtr.value != nullptr){
    print("Failed to get stream profile data!");
    exit(0);
  }

  final Pointer<Int> width = arena.allocate<Int>(4);
  final Pointer<Int> height = arena.allocate<Int>(4);
  nativeLib.rs2_get_video_stream_resolution(stream_profile, width, height, errorPtr);
  if(errorPtr.value != nullptr) {
    print("Failed to get video stream resolution data!");
    exit(0);
  }
  final int rows = height.value ~/ HEIGHT_RATIO;
  final int row_length = width.value ~/ WIDTH_RATIO;
  final int display_size = (rows + 1) * (row_length + 1);

  List<String> out = List<String>.filled(display_size + 1, " ");
  int out_index = 0; 

  while(true) {
    // This call waits until a new composite_frame is available
    // composite_frame holds a set of frames. It is used to prevent frame drops
    final Pointer<rs2_frame> frames = nativeLib.rs2_pipeline_wait_for_frames(pipeline, RS2_DEFAULT_TIMEOUT, errorPtr);
    checkError(errorPtr.value);

    /// Returns the number of frames embedded within the composite frame
    final int num_of_frames = nativeLib.rs2_embedded_frames_count(frames, errorPtr);
    checkError(errorPtr.value);

    for (int i = 0; i < num_of_frames; ++i) {
      final Pointer<rs2_frame> frame = nativeLib.rs2_extract_frame(frames, i, errorPtr);
      checkError(errorPtr.value);

      // Check if the given frame can be extended to depth frame interface
      // Accept only depth frames and skip other frames
      if (0 == nativeLib.rs2_is_frame_extendable_to(frame, rs2_extension.RS2_EXTENSION_DEPTH_FRAME, errorPtr)) {
        nativeLib.rs2_release_frame(frame);
        continue;
      }

      /// Retrieve depth data, configured as 16-bit depth values
      Pointer<Uint16> depth_frame_data = nativeLib.rs2_get_frame_data(frame, errorPtr).cast();
      checkError(errorPtr.value);

      /// Print a simple text-based representation of the image, by breaking it into 10x5 pixel regions and approximating the coverage of pixels within one meter 
      final List<int> coverage = List<int>.filled(row_length, 0);
      
      for (int y = 0; y < height.value; ++y) {
        for (int x = 0; x < width.value; ++x) {
          // Create a depth histogram to each row
          final int coverage_index = x ~/ WIDTH_RATIO;
          final int depth = depth_frame_data.value;  // <-- This is a void* though?
          depth_frame_data = Pointer.fromAddress(depth_frame_data.address + 2);
          if (depth > 0 && depth < one_meter) {
            coverage[coverage_index]++;
          }
        }

        if ((y % HEIGHT_RATIO) == (HEIGHT_RATIO - 1)) {
          for (int j = 0; j < row_length; ++j) {
            const List<String> pixels = [" ", ".", ":", "n", "h", "B", "X", "W", "W"];
            int pixel_index = ((coverage[j] / (HEIGHT_RATIO * WIDTH_RATIO / pixels.length)) % pixels.length).toInt();
            var test1 = out[out_index];
            var test2 = pixels[pixel_index];
            out_index++;
            coverage[j] = 0;
          }
          out[out_index] = "\n";
          out_index++;
        }
      }
      out[out_index] = "\n";
      out_index = 0;

      print("\n$out");

      nativeLib.rs2_release_frame(frame);
    }
    nativeLib.rs2_release_frame(frames);
  }
  /// Stop the pipeline streaming
  // THIS CODE WON'T RUN BECAUSE IT'S BELOW AN INFINITE LOOP!

  // nativeLib.rs2_pipeline_stop(pipeline, errorPtr);
  // checkError(errorPtr.value);

  // /// Release resources
  // nativeLib.rs2_delete_pipeline_profile(pipeline_profile);
  // nativeLib.rs2_delete_stream_profiles_list(stream_profile_list);
  // nativeLib.rs2_delete_stream_profile(stream_profile);
  // nativeLib.rs2_delete_config(config);
  // nativeLib.rs2_delete_pipeline(pipeline);
  // nativeLib.rs2_delete_device(dev);
  // nativeLib.rs2_delete_device_list(device_list);
  // nativeLib.rs2_delete_context(context);

  // arena.releaseAll();
}
