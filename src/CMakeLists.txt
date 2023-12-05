# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.

# Config for CMake
cmake_minimum_required(VERSION 3.10)
project(realsense_ffi_library VERSION 0.0.1 LANGUAGES CXX C)

# RealSense SDK config. These only build the stuff we need to reduce build time
# See https://dev.intelrealsense.com/docs/build-configuration
remove_definitions(-DUNICODE -D_UNICODE)
SET(BUILD_EXAMPLES OFF CACHE BOOL "Some option" FORCE)
SET(BUILD_GRPAHICAL_EXAMPLES OFF CACHE BOOL "Some option" FORCE)
SET(BUILD_TOOLS OFF CACHE BOOL "Some option" FORCE)
SET(BUILD_WITH_OPENMP ON CACHE BOOL "Some option" FORCE)


SET(BUILD_IPP_IW OFF CACHE BOOL "Some option" FORCE)
SET(BUILD_SHARED_LIBS ON CACHE BOOL "Some option" FORCE)
SET(BUILD_EASY_LOGGINGPP OFF CACHE BOOL "Some option" FORCE)
SET(BUILD_WITH_TM2 OFF CACHE BOOL "Some option" FORCE)
# set(realsense2_DIR "${CMAKE_SOURCE_DIR}/librealsense/CMake")

include_directories(BEFORE SYSTEM "${CMAKE_SOURCE_DIR}/librealsense/include")

# Compile the RealSense SDK and register with CMake
add_subdirectory(librealsense)

# Config for realsense_ffi
# add_library(realsense_internal SHARED "realsense_internal.cpp")
# set_target_properties(realsense_internal PROPERTIES
#   PUBLIC_HEADER realsense_internal.hpp
#   OUTPUT_NAME "realsense_internal"
# )
# target_compile_definitions(realsense_internal PUBLIC DART_SHARED_LIB)

add_library(realsense_ffi SHARED "realsense_ffi.cpp" "realsense_internal.cpp")
set_target_properties(realsense_ffi PROPERTIES
  PUBLIC_HEADER realsense_ffi.h
  OUTPUT_NAME "realsense_ffi"
)
target_compile_definitions(realsense_ffi PUBLIC DART_SHARED_LIB)

# Compile realsense_ffi
target_link_libraries(realsense_ffi PUBLIC librealsense) 
# "C:\\Program Files (x86)\\Intel RealSense SDK 2.0\\lib\\x64\\realsense2.lib")
