# Config for CMake
cmake_minimum_required(VERSION 3.10)
project(SICK_SCAN_XD_ffi_library VERSION 0.0.1 LANGUAGES CXX)

# SET(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)
# SET(ROS_VERSION 0)

# include_directories(BEFORE SYSTEM "${CMAKE_CURRENT_SOURCE_DIR}/sick_scan_xd/include/sick_scan_xd_api")
# include_directories(BEFORE SYSTEM "${CMAKE_CURRENT_SOURCE_DIR}/sick_scan_xd")

# add_subdirectory(sick_scan_xd)
# add_library(sick_scan_xd SHARED IMPORTED)
# set_target_properties(sick_scan_xd PROPERTIES IMPORTED_LOCATION lidar.dll)
# Config for SICK_SCAN_XD_ffi_library
add_library(lidar_ffi SHARED "lidar.cpp")
set_target_properties(lidar_ffi PROPERTIES
  PUBLIC_HEADER lidar.h
  PUBLIC_HEADER sick_scan_xd.h
  OUTPUT_NAME "lidar_ffi"
)

# Compile lidar_ffi
target_compile_definitions(lidar_ffi PUBLIC DART_SHARED_LIB)
# target_link_libraries(lidar_ffi sick_scan_xd_shared_lib)
