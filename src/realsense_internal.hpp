#include "realsense_ffi.h"
#include <librealsense2/rs.hpp>

namespace burt_rs {
  class RealSense {
    public: 
      // Fields
      rs2_error* error;
      rs2::device device;
      rs2::sensor sensor;

      // Defines the number of columns for each frame or zero for auto resolve
      int width;
      // Defines the number of lines for each frame or zero for auto resolve  
      int height;
      float depthScale;

      // Constructors/Destructors
      ~RealSense();

      BurtRsStatus init();
      BurtRsStatus start_stream();

      void checkError(rs2_error* error);
      uint16_t* getDepthFrame();
      const char* getDeviceName();

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