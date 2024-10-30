// #include <chrono>
#include <iostream>
// #include <thread>

// #include "lidar.h"

// Image* ReturnLatestImage(void* msg){
//     ReturnLatestImage * latestImage;
//     latestImage->buffer = msg->data;
//     latestImage->size = msg->height;
//     latestImage->capacity  = msg->width;

//     return latestImage;
// }
// static void exitOnError(const char* msg, int32_t error_code)
// {
//     printf("## ERROR sick_scan_xd_api_test: %s, error code %d\n", msg, error_code);
//     exit(EXIT_FAILURE);
// }

// static void apiTestCartesianPointCloudMsgCallback(SickScanApiHandle apiHandle, const SickScanPointCloudMsg* msg)
// {
//     printf("[Info]: apiTestCartesianPointCloudMsgCallback(apiHandle:%p): %dx%d pointcloud callback...\n", apiHandle, msg->width, msg->height);
// }

// int main(int argc, char** argv, const std::string& sick_scan_args, bool polling){
//   int32_t ret = SICK_SCAN_API_SUCCESS;
//   SickScanApiHandle apiHandle = 0;

//   if ((apiHandle = SickScanApiCreate(argc, argv)) == 0)
//     exitOnError("SickScanApiCreate failed", -1);

//   // Initialize a lidar and starts message receiving and processing
// #if __ROS_VERSION == 1
//   if ((ret = SickScanApiInitByLaunchfile(apiHandle, sick_scan_args.c_str())) != SICK_SCAN_API_SUCCESS)
//     exitOnError("SickScanApiInitByLaunchfile failed", ret);
// #else
//   if ((ret = SickScanApiInitByCli(apiHandle, argc, argv)) != SICK_SCAN_API_SUCCESS)
//     exitOnError("SickScanApiInitByCli failed", ret);
// #endif

// }

#include "lidar.h"

FFI_PLUGIN_EXPORT void updateLatestImage(void* apiHandle, void* pointCloudMsg) {
  std::cout << "Received frame" << std::endl;
}

FFI_PLUGIN_EXPORT Image getLatestImage() { 
  Image image;
  image.size = 15;
  image.data = nullptr;
  return image;
}
