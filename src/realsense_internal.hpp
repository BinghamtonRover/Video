#include "realsense_ffi.h"
#include <librealsense2/rs.hpp>

namespace burt_rs {
  class RealSense {
    public: 
      BurtRsConfig config;

      RealSense();
      ~RealSense();
      BurtRsStatus init();

      BurtRsStatus startStream();
      void stopStream();

      BurtRsFrames* getFrames();
      const char* getDeviceName();

    private:
      rs2::device device;
      rs2::depth_sensor sensor;
      rs2::pipeline pipeline;
      rs2::colorizer colorizer = rs2::colorizer();
  };
}