#include "realsense_ffi.h"

namespace burt_rs {
  class RealSense {
    public: 
      // Fields
      rs2_error* error;

      // Constructors/Destructors
      ~RealSense();

      // Methods
      void init();
      rs2_frame* getDepthFrame();
  };
}