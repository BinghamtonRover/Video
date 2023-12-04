#include "realsense_ffi.h"
#include "realsense.hpp"

// realsense_ffi.h declares global C functions and an empty struct called RealSense
// realsense.hpp declares a class burt_rs::RealSense with methods and fields
// This file implements the C functions by calling the C++ methods
//   1. Convert C RealSense* to the C++ burt_rs::RealSense* using reinterpret_cast()
//   2. Call the function on the C++ class as normal

NativeRealSense* RealSense_create() {
  // This method is different because it goes from C++ --> C instead of C --> C++
  auto ptr = new burt_rs::RealSense();
  return reinterpret_cast<NativeRealSense*>(ptr);
}

void RealSense_free(NativeRealSense* ptr) {
  delete reinterpret_cast<burt_rs::RealSense*>(ptr);
}

void RealSense_init(NativeRealSense* ptr) {
  reinterpret_cast<burt_rs::RealSense*>(ptr)->init();
}

rs2_frame* RealSense_getDepthFrame(NativeRealSense* ptr) {
  return reinterpret_cast<burt_rs::RealSense*>(ptr)->getDepthFrame();
}

void rs2_frame_free(rs2_frame* ptr) {
  // Can't use `delete` here because rs2_frames are allocated using malloc/calloc, not `new`
  free(ptr);
}
