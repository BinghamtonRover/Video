#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#include <stdint.h>

typedef struct Image{
  uint64_t size;
  // uint64_t capacity;
  // SickScanUint8Array buffer;
  void* data;
} Image;

FFI_PLUGIN_EXPORT void updateLatestImage(void* apiHandle, void* pointCloudMsg);
FFI_PLUGIN_EXPORT Image getLatestImage();
