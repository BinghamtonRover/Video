#include "realsense_ffi.h"
#include <librealsense2/rs.hpp>

namespace burt_rs {
  class RealSense {
    public: 
      BurtRsConfig config;

      RealSense();
      ~RealSense();
      BurtRsStatus init();
      const char* getDeviceName();

      BurtRsStatus startStream();
      void stopStream();

      BurtRsFrame* getDepthFrame();

    private:
      rs2::device device;
      rs2::pipeline pipeline;
  };
}

static rs2::colorizer colorizer = rs2::colorizer();
BurtRsFrame* colorize(BurtRsFrame* frame);
void freeFrame(BurtRsFrame* frames);
