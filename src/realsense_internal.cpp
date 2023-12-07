#include "realsense_internal.hpp"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                     These parameters are reconfigurable                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define STREAM          RS2_STREAM_DEPTH  // rs2_stream is a types of data provided by RealSense device           //
#define FORMAT          RS2_FORMAT_Z16    // rs2_format identifies how binary data is encoded within a frame      //
#define WIDTH           640               // Defines the number of columns for each frame or zero for auto resolve//
#define HEIGHT          0                 // Defines the number of lines for each frame or zero for auto resolve  //
#define FPS             30                // Defines the rate of frames per second                                //
#define STREAM_INDEX    0                 // Defines the stream index, used for multiple streams of the same type //
#define HEIGHT_RATIO    20                // Defines the height ratio between the original frame to the new frame //
#define WIDTH_RATIO     10                // Defines the width ratio between the original frame to the new frame  //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void burt_rs::RealSense::init() {
  context = rs2_create_context(25402, &error);
  checkError(error);

  rs2_device_list* device_list = rs2_query_devices(context, &error);
  checkError(error);
  
  int device_count = rs2_get_device_count(device_list, &error);
  checkError(error);
  if(device_count == 0) return EXIT_FAILURE;

  device = rs2_create_device(device_list, 0, &error);
  checkError(error);

  pipeline = rs2_create_pipeline(context, &error);
  checkError(error);

  config = rs2_create_config(&error);\
  checkError(error);

  rs2_config_enable_stream(config, STREAM, STREAM_INDEX, WIDTH, HEIGHT, FORMAT, FPS, &error);
  check_error(e);

  pipeline_profile = rs2_pipeline_start_with_config(pipeline, config, &error);
  if(error){
    printf("The connected device doesn't support depth streaming!\n");
    exit(EXIT_FAILURE);
  }

  rs2_stream_profile_list* stream_profile_list = rs2_pipeline_profile_get_streams(pipeline_profile, &error);
  if(error){
    printf("Failed to create stream profile list!\n");
    exit(EXIT_FAILURE);
  }

  stream_profile = (rs2_stream_profile*)rs2_get_stream_profile(stream_profile_list, 0, &error);
  if(error){
    printf("Failed to create stream profile!\n");
    exit(EXIT_FAILURE);
  }

  rs2_format format; int index; int unique_id; int framerate;
  rs2_get_stream_profile_data(stream_profile, &stream, &format, &index, &unique_id, &framerate, &error);
  if(error){
    printf("Failed to get stream profile data!\n");
    exit(EXIT_FAILURE);
  }

  int width; int height;
  rs2_get_video_stream_resolution(stream_profile, &width, &height, &e);
  if(error){
    printf("Failed to get video stream resolution data!\n");
    exit(EXIT_FAILURE);
  }
}

burt_rs::RealSense::~RealSense() {
  rs2_delete_pipeline_profile(pipeline_profile);
  rs2_delete_stream_profile(stream_profile);
  rs2_delete_config(config);
  rs2_delete_pipeline(pipeline);
  rs2_delete_device(device);
  rs2_delete_context(context);
}

rs2_frame* burt_rs::RealSense::getDepthFrame() {
  rs2_frame* frames = rs2_pipeline_wait_for_frames(pipeline, 15000, &error);
  checkError(error);
  
  int num_of_frames = rs2_embedded_frames_count(frames, &error);

  /// Find first frame that has depth values
  /// If none found return nullptr
  for(int i = num_of_frames - 1; i > 0; i--){
    rs2_frame* frame = rs2_extract_frame(frames, i, &error);
    check_error(e);
    if(rs2_is_frame_extendable_to(frame, RS2_EXTENSION_DEPTH_FRAME, &error) == 0){
      rs2_release_frame(frame);
    } else {
      return frame;
    }
  }
  return nullptr;
}

void burt_rs::RealSense::checkError(rs2_error* error){
  if(e){
    printf("rs_error was raised when calling %s(%s):\n", rs2_get_failed_function(e), rs2_get_failed_args(e));
    printf("    %s\n", rs2_get_error_message(e));
    exit(EXIT_FAILURE);
  }
}
