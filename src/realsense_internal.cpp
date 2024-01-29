#include "realsense_internal.hpp"
#include <librealsense2/rs.hpp>

#include <iostream>
#include <unistd.h>

using namespace std;

// -------------------- Device methods --------------------
burt_rs::RealSense::RealSense() { }
burt_rs::RealSense::~RealSense() { }

BurtRsStatus burt_rs::RealSense::init() {
  rs2::context context;
  rs2::device_list devices = context.query_devices();
  if (devices.size() == 0) {
    cout << "[BurtRS] No devices found" << endl;
    return BurtRsStatus::BurtRsStatus_no_device;
  } else if (devices.size() > 1) {
    cout << "[BurtRS] Multiple devices found!" << endl;
    return BurtRsStatus::BurtRsStatus_too_many_devices;
  }
  device = devices[0];
  rs2::depth_sensor sensor = device.first<rs2::depth_sensor>();
  auto scale = sensor.get_depth_scale();
  if (scale == 0) {
    return BurtRsStatus::BurtRsStatus_scale_unknown;
  } else {
    config.scale = scale;
  }
  return BurtRsStatus::BurtRsStatus_ok;
}

const char* burt_rs::RealSense::getDeviceName() {
  if (device.supports(RS2_CAMERA_INFO_NAME)) {
    return device.get_info(RS2_CAMERA_INFO_NAME);
  } else {
    return "Unknown device";
  }
}

// -------------------- Stream methods --------------------

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

// -------------------- Frame methods --------------------

// NativeFrames* copyFrame(rs2::frame frame) {
//   // Copy into a new buffer
//   const int length = frame.get_data_size();
//   const uint16_t* data = frame.get_data();
//   uint16_t* copy = new uint16_t[length];
//   for (int i = 0; i < length; i++) {
//     copy[i] = data[i];
//   }
//   // Send the buffer and length
//   auto result = new NativeFrames;
//   result->data = copy;
//   result->length = length;
//   return result;
// }

NativeFrames* burt_rs::RealSense::getDepthFrame() {
  // Get the depth and color frames
  rs2::frameset frames;
  if (!pipeline.poll_for_frames(&frames)) return nullptr;
  rs2::depth_frame depth_frame = frames.get_depth_frame();
  rs2::frame colorized_frame = colorizer.colorize(depth_frame);

  // Copy both frames -- TODO: optimize this
  int depth_length = depth_frame.get_data_size();
  int colorized_length = colorized_frame.get_data_size();
  if (depth_length == 0 || colorized_length == 0) return nullptr;
  uint16_t* depth_copy = new uint16_t[depth_length];
  uint8_t* colorized_copy = new uint8_t[colorized_length];

  // Copy all the data in the depth frame
  const uint16_t* depth_data = static_cast<const uint16_t*>(depth_frame.get_data());
  for (int i = 0; i < depth_length; i++) {
    depth_copy[i] = depth_data[i];
  }

  // Copy all the data in the colorized frame
  const uint8_t* colorized_data = static_cast<const uint8_t*>(colorized_frame.get_data());
  for (int i = 0; i < colorized_length; i++) {
    colorized_copy[i] = colorized_data[i];
  }

  // Return both frames
  return new NativeFrames {
    depth_data: depth_copy,
    depth_length: depth_length,
    colorized_data: colorized_copy,
    colorized_length: colorized_length,
  };

}

//   cout << "[BurtRS] Colorizing " << depthFrame << endl;
//   rs2::depth_frame* framePtr = reinterpret_cast<rs2::depth_frame*>(depthFrame->rs_pointer);
//   cout << "[BurtRS] rs2::framePtr: " << framePtr << endl;
//   rs2::depth_frame frame = *framePtr;
//   cout << "[BurtRS] Running colorizer..." << endl;
//   rs2::frame colorized = colorizer.process(*framePtr);
//   rs2::frame* colorized2 = new rs2::depth_frame(frame);
//   colorized2->keep();
//   cout << "[BurtRS] Result: " << colorized2 << endl;
//   cout << "[BurtRS] Kept result" << endl;
//   auto result = new BurtRsFrame;
//   result->data = colorized2->get_data();
//   result->length = colorized2->get_data_size();
//   result->rs_pointer = colorized2;
//   return result;
// }

void freeFrame(NativeFrames* frames) {
  delete[] frames->depth_data;
  delete[] frames->colorized_data;
}
