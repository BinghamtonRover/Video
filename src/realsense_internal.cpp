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

BurtRsFrame* burt_rs::RealSense::getDepthFrame() {
  rs2::frameset frames;
  if (!pipeline.poll_for_frames(&frames)) return nullptr;
  rs2::depth_frame frame = frames.get_depth_frame();
  rs2::depth_frame* frame2 = new rs2::depth_frame(frame);
  // frame.keep();
  auto result = new BurtRsFrame;
  result->data = frame2->get_data();
  result->length = frame2->get_data_size();
  result->rs_pointer = frame2;
  return result;
}

BurtRsFrame* colorize(BurtRsFrame* depthFrame) {
  cout << "[BurtRS] Colorizing " << depthFrame << endl;
  rs2::depth_frame* framePtr = reinterpret_cast<rs2::depth_frame*>(depthFrame->rs_pointer);
  cout << "[BurtRS] rs2::framePtr: " << framePtr << endl;
  rs2::depth_frame frame = *framePtr;
  cout << "[BurtRS] Running colorizer..." << endl;
  rs2::frame colorized = colorizer.process(*framePtr);
  rs2::frame* colorized2 = new rs2::depth_frame(frame);
  colorized2->keep();
  cout << "[BurtRS] Result: " << colorized2 << endl;
  cout << "[BurtRS] Kept result" << endl;
  auto result = new BurtRsFrame;
  result->data = colorized2->get_data();
  result->length = colorized2->get_data_size();
  result->rs_pointer = colorized2;
  return result;
}

void freeFrame(BurtRsFrame* frames) {
  rs2::frame* frame = reinterpret_cast<rs2::frame*>(frames->rs_pointer);
  frame->~frame();
}
