#include <librealsense>

#include "librealsense.h"

// SETUP 
FFI_PLUGIN_EXPORT rs2_context* rs2_create_context(int api_version, rs2_error** error){
    return rs2_create_context(api_version, error);
}

FFI_PLUGIN_EXPORT rs2_device_list* rs2_query_devices(rs2_context* context, rs2_error** error){
    return rs2_query_devices(context, error);
}

FFI_PLUGIN_EXPORT int rs2_get_device_count(rs2_device_list* device_list, rs2_error** error){
    return rs2_get_device_count(device_list, error);
}

FFI_PLUGIN_EXPORT rs2_device* rs2_create_device(rs2_device_list* device_list, int index, rs2_error** error){
    return rs2_create_device(device_list, index, error)
}
FFI_PLUGIN_EXPORT rs2_pipeline* rs2_create_pipeline(rs2_context* context, rs2_error** error);
FFI_PLUGIN_EXPORT rs2_config* rs2_create_config(rs2_error** error);
FFI_PLUGIN_EXPORT void rs2_config_enable_stream(rs2_config* config, int stream, int index, int width, int height, int format, int framerate, rs2_error** error);
FFI_PLUGIN_EXPORT rs2_pipeline_profile* pipeline_profile rs2_pipeline_start_with_config(rs2_pipeline* pipeline, rs2_config* config, rs2_error** error);
FFI_PLUGIN_EXPORT rs2_stream_profile_list* rs2_pipeline_profile_get_streams(rs2_pipeline_profile* pipeline_profile, rs2_error** error);
FFI_PLUGIN_EXPORT rs2_stream_profile* rs2_get_stream_profile(rs2_stream_profile_list* stream_profile_list, int index, rs2_error** error);
FFI_PLUGIN_EXPORT void rs2_get_stream_profile_data(rs2_stream_profile* stream_profile, int* stream, int* format, int* index, int* unique_id, int* framerate, rs2_error** error);
FFI_PLUGIN_EXPORT void rs2_get_video_stream_resolution(rs2_stream_profile* profile, int* width, int* height, rs2_error** error);
