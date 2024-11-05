
#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#include <sick_scan_api.h>
#include <stdint.h>


typedef struct Image{
  uint64_t height;
  uint64_t width;

  // uint64_t capacity;
  // SickScanUint8Array buffer;
  uint8_t* data;
} Image;

FFI_PLUGIN_EXPORT void updateLatestImage(void* apiHandle, void* pointCloudMsg);
FFI_PLUGIN_EXPORT Image getLatestImage();
