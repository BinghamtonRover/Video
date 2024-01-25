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

BurtRsFrames* burt_rs::RealSense::getFrames() {
  BurtRsFrames* result = new BurtRsFrames;
  // rs2::frameset frames;
  // if (!pipeline.poll_for_frames(&frames)) return nullptr;
  rs2::frameset frames = pipeline.wait_for_frames();
  rs2::frame frame = frames.get_depth_frame();
  rs2::frame colorized = colorizer.colorize(frame);
  frame.keep();
  result->frame_pointer = &frame;
  result->depth_frame = (uint16_t*) frame.get_data();
  result->depth_length = frame.get_data_size();
  result->colorized_frame = (uint8_t*) colorized.get_data();
  result->colorized_length = colorized.get_data_size();
  return result;
}

void freeFrames(BurtRsFrames* frames) {
  rs2::frame* frame = (rs2::frame*) frames->frame_pointer;
  frame->~frame();
}
