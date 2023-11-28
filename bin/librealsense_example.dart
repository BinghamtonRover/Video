import "package:video/video.dart";
import "dart:ffi/ffi.dart";
import "package:ffi/ffi.dart";
import "dart:io";

final arena = Arena();

/// Function calls to librealsense may raise errors of type rs_error*/
void checkError(Pointer<rs2_error> e)
{
    if (e != nullptr)
    {
        print("rs_error was raised when calling ${nativeLib.rs2_get_failed_function(e)}(${nativeLib.rs2_get_failed_args(e)})");
        print("    ${nativeLib.rs2_get_error_message(e)}");
        exit(0);
    }
}


void main(){
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

  //Pointer<uint16_t> one_meter = (uint16_t)(1.0f / get_depth_unit_value(dev));

  /// Create a pipeline to configure, start and stop camera streaming
  final Pointer<rs2_pipeline> pipeline =  nativeLib.rs2_create_pipeline(context, errorPtr);
  checkError(errorPtr.value);

  /// Create a config instance, used to specify hardware configuration
  Pointer<rs2_config> config = nativeLib.rs2_create_config(errorPtr);
  checkError(errorPtr.value);

  /// Request a specific configuration
  /// Parameters are reconfigurable
  nativeLib.rs2_config_enable_stream(config, rs2_stream.RS2_STREAM_DEPTH, 0, 640, 0, rs2_format.RS2_FORMAT_Z16, 30, errorPtr);
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

  final Pointer<Int32> stream = arena.allocate(4); 
  final Pointer<Int32> format = arena.allocate(4);
  final Pointer<Int> index = arena.allocate(4); 
  final Pointer<Int> unique_id = arena.allocate(4);
  final Pointer<Int> framerate = arena.allocate(4);
  nativeLib.rs2_get_stream_profile_data(stream_profile, stream, format, index, unique_id, framerate, errorPtr);
  if(errorPtr.value != nullptr){
    print("Failed to get stream profile data!");
    exit(0);
  }

  final Pointer<Int> width = arena.allocate(4);
  final Pointer<Int> height = arena.allocate(4);
  nativeLib.rs2_get_video_stream_resolution(stream_profile, width, height, errorPtr);
  if(errorPtr.value != nullptr) {
    print("Failed to get video stream resolution data!");
    exit(0);
  }
  final int rows = height.value ~/ 20;
  final int row_length = width.value ~/ 10;
  final int display_size = (rows + 1) * (row_length + 1);
  final int buffer_size = display_size;

  final Pointer<Char> buffer = calloc(display_size);
  final Pointer<Char> out = nullptr;


  while(true) {
    // This call waits until a new composite_frame is available
    // composite_frame holds a set of frames. It is used to prevent frame drops
    final Pointer<rs2_frame> frames = nativeLib.rs2_pipeline_wait_for_frames(pipeline, RS2_DEFAULT_TIMEOUT, errorPtr);
    checkError(errorPtr.value);

    /// Returns the number of frames embedded within the composite frame
    final int num_of_frames = nativeLib.rs2_embedded_frames_count(frames, errorPtr);
    checkError(errorPtr.value);

    int i = 0;
    for (i = 0; i < num_of_frames; ++i) {
      final Pointer<rs2_frame> frame = nativeLib.rs2_extract_frame(frames, i, errorPtr);
      checkError(errorPtr.value);

      // Check if the given frame can be extended to depth frame interface
      // Accept only depth frames and skip other frames
      if (0 == nativeLib.rs2_is_frame_extendable_to(frame, rs2_extension.RS2_EXTENSION_DEPTH_FRAME, errorPtr)){
        nativeLib.rs2_release_frame(frame);
        continue;
      }

      /// Retrieve depth data, configured as 16-bit depth values */
      final Pointer<void> depth_frame_data = nativeLib.rs2_get_frame_data(frame, errorPtr);
      checkError(errorPtr.value);

          /* Print a simple text-based representation of the image, by breaking it into 10x5 pixel regions and approximating the coverage of pixels within one meter */
      out.value = buffer.value;
      int x, y, i;
      final Pointer<Int> coverage = calloc(row_length, sizeof(int));

        for (y = 0; y < height.value; ++y){
          for (x = 0; x < width.value; ++x){
              // Create a depth histogram to each row
              final int coverage_index = x ~/ 10;
              final int depth = depth_frame_data++;
              if (depth > 0 && depth < one_meter)
                  ++coverage[coverage_index];
          }

          if ((y % 10) == (9)){
              for (i = 0; i < (row_length); ++i)
              {
                  static const char* pixels = " .:nhBXWW";
                  int pixel_index = (coverage[i] / (HEIGHT_RATIO * WIDTH_RATIO / sizeof(pixels)));
                  *out++ = pixels[pixel_index];
                  coverage[i] = 0;
              }
              *out++ = '\n';
          }
        }
        *out++ = 0;
        printf("\n%s", buffer);

        free(coverage);
        rs2_release_frame(frame);
      }

      rs2_release_frame(frames);
  }

  /// Stop the pipeline streaming
  nativeLib.rs2_pipeline_stop(pipeline, errorPtr);
  checkError(errorPtr.value);

  /// Release resources
  free(buffer);
  nativeLib.rs2_delete_pipeline_profile(pipeline_profile);
  nativeLib.rs2_delete_stream_profiles_list(stream_profile_list);
  nativeLib.rs2_delete_stream_profile(stream_profile);
  nativeLib.rs2_delete_config(config);
  nativeLib.rs2_delete_pipeline(pipeline);
  nativeLib.rs2_delete_device(dev);
  nativeLib.rs2_delete_device_list(device_list);
  nativeLib.rs2_delete_context(ctx);

  arena.releaseAll();
}
