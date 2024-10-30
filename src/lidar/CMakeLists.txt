# Config for CMake
cmake_minimum_required(VERSION 3.10)
project(SICK_SCAN_XD_ffi_library VERSION 0.0.1 LANGUAGES CXX)

# include_directories(BEFORE SYSTEM "${CMAKE_CURRENT_SOURCE_DIR}/sick_scan_xd/include/sick_scan_xd_api")

# add_subdirectory(sick_scan_xd)

# Config for SICK_SCAN_XD_ffi_library
add_library(lidar_ffi SHARED "lidar.cpp")
set_target_properties(lidar_ffi PROPERTIES
  PUBLIC_HEADER lidar.h
  OUTPUT_NAME "lidar_ffi"
)

# Compile lidar_ffi
target_compile_definitions(lidar_ffi PUBLIC DART_SHARED_LIB)
