#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include <librealsense2/rs.h>
#include <librealsense2/h/rs_pipeline.h>
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
struct RealSense;

RealSense* RealSense_create();
void RealSense_free(RealSense* ptr);
void RealSense_init(RealSense* ptr);
rs2_frame* RealSense_getDepthFrame(RealSense* ptr);

void rs2_frame_free(rs2_frame* ptr);

#ifdef __cplusplus
}
#endif
