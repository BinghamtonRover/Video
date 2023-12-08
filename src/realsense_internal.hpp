#include "realsense_ffi.h"

namespace burt_rs {
  class RealSense {
    public: 
      // Fields
      rs2_error* error;
      rs2_device* device;
      // Defines the number of columns for each frame or zero for auto resolve
      int width;
      // Defines the number of lines for each frame or zero for auto resolve  
      int height;

      // Constructors/Destructors
      ~RealSense();

      // Methods
      void checkError(rs2_error* error);
      void init();
      uint16_t* getDepthFrame();

    private:
      rs2_context* context;
      rs2_device_list* device_list;
      rs2_config* config;
      rs2_pipeline* pipeline;
      rs2_pipeline_profile* pipeline_profile;
      rs2_stream_profile_list* stream_profile_list;
      rs2_stream_profile* stream_profile;
  };
}