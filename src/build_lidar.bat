rem Build OpenCV and opencv_ffi
if not exist build mkdir build
cd build
cmake ../lidar
cmake --build .
cd ..