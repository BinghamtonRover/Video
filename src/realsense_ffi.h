#ifndef RS_FFI
#define RS_FFI

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include <librealsense2/rs.h>
#include <librealsense2/h/rs_option.h>
#include <librealsense2/h/rs_frame.h>

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

// A fake ("opaque") C-friendly struct that we'll use a pointer to.
// This pointer will actually represent the RealSense class in C++
struct NativeRealSense;
typedef struct NativeRealSense NativeRealSense;

FFI_PLUGIN_EXPORT NativeRealSense* RealSense_create();
FFI_PLUGIN_EXPORT void RealSense_free(NativeRealSense* ptr);
FFI_PLUGIN_EXPORT void RealSense_init(NativeRealSense* ptr);
FFI_PLUGIN_EXPORT rs2_frame* RealSense_getDepthFrame(NativeRealSense* ptr);

FFI_PLUGIN_EXPORT void rs2_frame_free(rs2_frame* ptr);

#ifdef __cplusplus
}
#endif

#endif
