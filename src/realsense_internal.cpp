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

NativeFrames* burt_rs::RealSense::getDepthFrame() {
  // Get the depth and color frames
  // cout << "[BurtRS] Getting frames... " << endl;
  rs2::frameset frames;
  if (!pipeline.poll_for_frames(&frames)) return nullptr;
  // cout << "[BurtRS]   Getting depth frame" << endl;
  rs2::depth_frame depth_frame = frames.get_depth_frame();
  // cout << "[BurtRS]   Getting color frame" << endl;
  rs2::frame colorized_frame = colorizer.colorize(depth_frame);

  // Copy both frames -- TODO: optimize this to be a move instead
  // cout << "[BurtRS]   Initializing copies" << endl;
  int depth_length = depth_frame.get_data_size();
  int colorized_length = colorized_frame.get_data_size();
  if (depth_length == 0 || colorized_length == 0) return nullptr;
  uint8_t* depth_copy = new uint8_t[depth_length];
  uint8_t* colorized_copy = new uint8_t[colorized_length];

  // Copy all the data in the depth frame
  // cout << "[BurtRS]   Copying depth frame" << endl;
  const uint8_t* depth_data = static_cast<const uint8_t*>(depth_frame.get_data());
  for (int i = 0; i < depth_length; i++) {
    depth_copy[i] = depth_data[i];
  }

  // Copy all the data in the colorized frame
  // cout << "[BurtRS]   Copying colorized frame" << endl;
  const uint8_t* colorized_data = static_cast<const uint8_t*>(colorized_frame.get_data());
  for (int i = 0; i < colorized_length; i++) {
    colorized_copy[i] = colorized_data[i];
  }
  // cout << "[BurtRS]   Done!" << endl;

  // Return both frames
  return new NativeFrames {
    depth_data: depth_copy,
    depth_length: depth_length,
    colorized_data: colorized_copy,
    colorized_length: colorized_length,
  };
}

void freeFrame(NativeFrames* frames) {
  delete[] frames->depth_data;
  delete[] frames->colorized_data;
}
