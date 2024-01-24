#include "realsense_internal.hpp"
#include <librealsense2/rs.hpp>

#include <iostream>
#include <unistd.h>

using namespace std;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                     These parameters are reconfigurable                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define STREAM          RS2_STREAM_DEPTH  // rs2_stream is a types of data provided by RealSense device           //
#define FORMAT          RS2_FORMAT_Z16    // rs2_format identifies how binary data is encoded within a frame      //
#define WIDTH           640               // Defines the number of columns for each frame or zero for auto resolve//
#define HEIGHT          0                 // Defines the number of lines for each frame or zero for auto resolve  //
#define FPS             30                // Defines the rate of frames per second                                //
#define STREAM_INDEX    0                 // Defines the stream index, used for multiple streams of the same type //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

const char* burt_rs::RealSense::getDeviceName() {
  if (device.supports(RS2_CAMERA_INFO_NAME)) {
    return device.get_info(RS2_CAMERA_INFO_NAME);
  } else {
    return "Unknown device";
  }
}

BurtRsStatus burt_rs::RealSense::init() {
  rs2::context context;
  rs2::device_list devices = context.query_devices();
  if (devices.size() == 0) {
    cout << "[BurtRS] No devices found" << endl;
    return BurtRsStatus::BurtRsStatus_no_device;
  } else if (devices.size() > 1) {
    cout << "[BurtRS] Multiple devices found!" << endl;
    return BurtRsStatus::BurtRsStatus_too_many_devices;
  } else {
    device = devices[0];
  }
  sensor = device.first<rs2::depth_sensor>();
  auto scale = sensor.get_depth_scale();
  if (scale == 0) {
    return BurtRsStatus::BurtRsStatus_scale_unknown;
  } else {
    config.scale = scale;
  }
  return BurtRsStatus::BurtRsStatus_ok;
}

BurtRsStatus burt_rs::RealSense::startStream() {
  auto profile = pipeline.start();
  auto frames = pipeline.wait_for_frames();
  auto frame = frames.get_depth_frame();
  auto width = frame.get_width();
  auto height = frame.get_height();

  if (width == 0 || height == 0) {
    return BurtRsStatus::BurtRsStatus_resolution_unknown;
  } else {
    config.width = width;
    config.height = height;
    return BurtRsStatus::BurtRsStatus_ok;
  }
}

void burt_rs::RealSense::stopStream() {
  pipeline.stop();
}

burt_rs::RealSense::~RealSense() {
  stopStream();
}

BurtRsFrames* burt_rs::RealSense::getFrames() {
  BurtRsFrames* result = new BurtRsFrames;
  rs2::frameset frames;
  pipeline.poll_for_frames(&frames);
  rs2::frame depth = frames.get_depth_frame();
  rs2::frame colorized = colorizer.colorize(depth);
  result->depth_frame = (uint16_t*) depth.get_data();
  result->depth_length = depth.get_data_size();
  result->colorized_frame = (uint8_t*) colorized.get_data();
  result->colorized_length = colorized.get_data_size();
  return result;
}

// uint16_t* burt_rs::RealSense::getDepthFrame() {
//   rs2_frame* frames = rs2_pipeline_wait_for_frames(pipeline, 15000, &error);
//   checkError(error);
  
//   int num_of_frames = rs2_embedded_frames_count(frames, &error);

//   /// Find first frame that has depth values
//   /// If none found return nullptr
//   for(int i = num_of_frames - 1; i > 0; i--){
//     rs2_frame* frame = rs2_extract_frame(frames, i, &error);
//     checkError(error);
//     if(rs2_is_frame_extendable_to(frame, RS2_EXTENSION_DEPTH_FRAME, &error) == 0){
//       rs2_release_frame(frame);
//     } else {
//       uint16_t* depth_frame_data = (uint16_t*)(rs2_get_frame_data(frame, &error));
//       checkError(error);
//       return depth_frame_data;
//     }
//   }
//   return nullptr;
// }

// void burt_rs::RealSense::checkError(rs2_error* error){
//   if(error){
//     printf("rs_error was raised when calling %s(%s):\n", rs2_get_failed_function(error), rs2_get_failed_args(error));
//     printf("    %s\n", rs2_get_error_message(error));
//     exit(EXIT_FAILURE);
//   }
// }

// float burt_rs::RealSense::getDepthScale() {
//   rs2_error* e = 0;
//   rs2_sensor_list* sensor_list = rs2_query_sensors(device, &e);
//   checkError(e);

//   int num_of_sensors = rs2_get_sensors_count(sensor_list, &e);
//   checkError(e);

//   float depth_scale = 0;
//   int is_depth_sensor_found = 0;
//   int i;
//   for (i = 0; i < num_of_sensors; ++i)
//   {
//       rs2_sensor* sensor = rs2_create_sensor(sensor_list, i, &e);
//       checkError(e);

//       // Check if the given sensor can be extended to depth sensor interface
//       is_depth_sensor_found = rs2_is_sensor_extendable_to(sensor, RS2_EXTENSION_DEPTH_SENSOR, &e);
//       checkError(e);

//       if (1 == is_depth_sensor_found)
//       {
//           sleep(1);
//           depth_scale = rs2_get_depth_scale(sensor, &e);
//           checkError(e);
//           rs2_delete_sensor(sensor);
//           break;
//       }
//       rs2_delete_sensor(sensor);
//   }
//   rs2_delete_sensor_list(sensor_list);

//   if (0 == is_depth_sensor_found)
//   {
//       printf("Depth sensor not found!\n");
//       exit(EXIT_FAILURE);
//   }

//   return depth_scale;
// }
