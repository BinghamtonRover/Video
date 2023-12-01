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

// SETUP 
FFI_PLUGIN_EXPORT rs2_context* rs2_create_context(int api_version, rs2_error** error);
FFI_PLUGIN_EXPORT rs2_device_list* rs2_query_devices(rs2_context* context, rs2_error** error);
FFI_PLUGIN_EXPORT int rs2_get_device_count(rs2_device_list* device_list, rs2_error** error);
FFI_PLUGIN_EXPORT rs2_device* rs2_create_device(rs2_device_list*, int index, rs2_error** error);
FFI_PLUGIN_EXPORT rs2_pipeline* rs2_create_pipeline(rs2_context* context, rs2_error** error);
FFI_PLUGIN_EXPORT rs2_config* rs2_create_config(rs2_error** error);
FFI_PLUGIN_EXPORT void rs2_config_enable_stream(rs2_config* config, int stream, int index, int width, int height, int format, int framerate, rs2_error** error);
FFI_PLUGIN_EXPORT rs2_pipeline_profile* pipeline_profile rs2_pipeline_start_with_config(rs2_pipeline* pipeline, rs2_config* config, rs2_error** error);
FFI_PLUGIN_EXPORT rs2_stream_profile_list* rs2_pipeline_profile_get_streams(rs2_pipeline_profile* pipeline_profile, rs2_error** error);
FFI_PLUGIN_EXPORT rs2_stream_profile* rs2_get_stream_profile(rs2_stream_profile_list* stream_profile_list, int index, rs2_error** error);
FFI_PLUGIN_EXPORT void rs2_get_stream_profile_data(rs2_stream_profile* stream_profile, int* stream, int* format, int* index, int* unique_id, int* framerate, rs2_error** error);
FFI_PLUGIN_EXPORT void rs2_get_video_stream_resolution(rs2_stream_profile* profile, int* width, int* height, rs2_error** error);

// READING / ANALYZING FRAMES
FFI_PLUGIN_EXPORT rs2_frame* rs2_pipeline_wait_for_frames(rs2_pipeline* pipeline, unsigned int timeout, rs2_error** error);
FFI_PLUGIN_EXPORT int rs2_embedded_frames_count(rs2_frames* frames, rs2_error** error);
FFI_PLUGIN_EXPORT rs2_frame* rs2_extract_frame(rs2_frame* frames, int i, rs2_error** error);
FFI_PLUGIN_EXPORT int rs2_is_frame_extendable_to(rs2_frame* frame, rs2_extension extension_type, rs2_error** error);
FFI_PLUGIN_EXPORT void rs2_release_frame(rs2_frame* frame);

// Stop the pipeline streaming
FFI_PLUGIN_EXPORT void rs2_pipeline_stop(rs2_pipeline* pipeline, rs2_error** error);
FFI_PLUGIN_EXPORT void rs2_delete_pipeline_profile(rs2_pipeline_profile* pipeline_profile);
FFI_PLUGIN_EXPORT void rs2_delete_stream_profiles_list(rs2_stream_profile_list* profile_list);
FFI_PLUGIN_EXPORT void rs2_delete_stream_profile(rs2_stream_profile* stream_profile);
FFI_PLUGIN_EXPORT void rs2_delete_config(rs2_config* config);
FFI_PLUGIN_EXPORT void rs2_delete_pipeline(rs2_pipeline* pipeline);
FFI_PLUGIN_EXPORT void rs2_delete_device(rs2_device* dev);
FFI_PLUGIN_EXPORT void rs2_delete_device_list(rs2_device_list* device_list);
FFI_PLUGIN_EXPORT void rs2_delete_context(rs2_context* ctx);

#ifdef __cplusplus
}
#endif
