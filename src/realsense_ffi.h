#pragma once

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
	BurtRsStatus_ok,
	BurtRsStatus_no_device,
	BurtRsStatus_too_many_devices,
	BurtRsStatus_resolution_unknown,
	BurtRsStatus_scale_unknown,
} BurtRsStatus;

typedef struct {
	int width;
	int height;
	float scale;
} BurtRsConfig;

typedef struct {
	uint16_t* depth_frame;
	uint8_t* colorized_frame;
	int depth_length;
	int colorized_length;
} BurtRsFrames;

// A fake ("opaque") C-friendly struct that we'll use a pointer to.
// This pointer will actually represent the RealSense class in C++
struct NativeRealSense;
typedef struct NativeRealSense NativeRealSense;

FFI_PLUGIN_EXPORT NativeRealSense* RealSense_create();
FFI_PLUGIN_EXPORT void RealSense_free(NativeRealSense* ptr);
FFI_PLUGIN_EXPORT BurtRsStatus RealSense_init(NativeRealSense* ptr);
FFI_PLUGIN_EXPORT const char* RealSense_getDeviceName(NativeRealSense* ptr);
// FFI_PLUGIN_EXPORT int RealSense_getWidth(NativeRealSense* ptr);
// FFI_PLUGIN_EXPORT int RealSense_getHeight(NativeRealSense* ptr);
FFI_PLUGIN_EXPORT BurtRsFrames *RealSense_getFrames(NativeRealSense *ptr);
// FFI_PLUGIN_EXPORT float RealSense_getDepthScale(NativeRealSense* ptr);

// FFI_PLUGIN_EXPORT void rs2_frame_free(rs2_frame* ptr);

#ifdef __cplusplus
}
#endif
