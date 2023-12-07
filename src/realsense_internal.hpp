#include "realsense_ffi.h"

namespace burt_rs {
  class RealSense {
    public: 
      // Fields
      rs2_error* error;
      rs2_device* device;

      // Constructors/Destructors
      ~RealSense();

      // Methods
      void checkError(rs2_error* error);
      void init();
      rs2_frame* getDepthFrame();

    private:
      rs2_context* context;
      rs2_pipeline* pipeline;
      rs2_config* config;
      rs2_pipeline_profile* pipeline_profile;
      rs2_stream_profile* stream_profile;
      rs2_stream stream;
  };
}