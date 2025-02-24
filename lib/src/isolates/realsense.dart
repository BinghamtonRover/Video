import "dart:ffi" as ffi;
import "dart:io";
import "dart:math";

import "package:burt_network/burt_network.dart";
import "package:dartcv4/dartcv.dart" hide min, pow, sqrt;
import "package:ffi/ffi.dart";
import "package:protobuf/protobuf.dart";
import "package:video/src/generated/librealsense_bindings.dart";
import "package:video/utils.dart";
import "package:video/video.dart";

String get _path {
  if (Platform.isWindows) {
    return "realsense2d.dll";
  } else if (Platform.isMacOS) {
    return "librealsense2.dylib";
  } else if (Platform.isLinux) {
    return "librealsense2.so";
  }
  throw UnsupportedError("Unsupported platform");
}

/// Native bindings for the realsense SDK
final RealsenseBindings librealsense = RealsenseBindings(
  ffi.DynamicLibrary.open(_path),
);

/// An isolate to read RGB, depth, and colorized frames from the RealSense.
///
/// While using the RealSense SDK for depth streaming, OpenCV cannot access the standard RGB frames,
/// so it is necessary for this isolate to grab the RGB frames as well.
///
/// Since the RealSense is being used for autonomy, certain settings that could interfere with the
/// autonomy program are not allowed to be changed, even for the RGB camera.
class RealsenseIsolate extends CameraIsolate {
  /// The frame queue for depth point clouds
  late ffi.Pointer<rs2_frame_queue> pointCloudQueue;

  /// The processing block for 3d point clouds
  late ffi.Pointer<rs2_processing_block> pointCloud;

  /// The frame queue for the decimation filter
  late ffi.Pointer<rs2_frame_queue> filterQueue;

  /// The processing block for the decimation filter
  late ffi.Pointer<rs2_processing_block> decimationFilter;

  /// The processing block for the threshold filter
  late ffi.Pointer<rs2_processing_block> thresholdFilter;

  /// The processing block for the temporal filter
  late ffi.Pointer<rs2_processing_block> temporalFilter;

  /// The frame queue for the depth alignment process
  late ffi.Pointer<rs2_frame_queue> depthAlignQueue;

  /// The processor for depth alignment
  late ffi.Pointer<rs2_processing_block> depthAlign;

  /// The frame queue for the depth colorizer
  late ffi.Pointer<rs2_frame_queue> colorizerQueue;

  /// The processing block for the depth colorizer
  late ffi.Pointer<rs2_processing_block> colorizer;

  /// The realsense context for the isolate
  ffi.Pointer<rs2_context> context = ffi.nullptr;

  /// The device being read
  ffi.Pointer<rs2_device> device = ffi.nullptr;

  /// The pipeline used for streaming
  ffi.Pointer<rs2_pipeline> pipeline = ffi.nullptr;

  /// The pipeline profile used to stream images from [pipeline]
  ffi.Pointer<rs2_pipeline_profile> pipelineProfile = ffi.nullptr;

  /// The configuration for the pipeline
  ffi.Pointer<rs2_config> config = ffi.nullptr;

  /// The resolution in pixels of the depth frame
  Resolution? depthResolution;

  /// The resolution in pixels of the RGB frame
  Resolution? rgbResolution;

  /// Default constructor for the Realsense Isolate
  ///
  /// This will initialize the fields for alignmenet and processing queues,
  /// which do not rely on a specific device
  RealsenseIsolate({required super.details}) {
    pointCloud = librealsense.rs2_create_pointcloud(ffi.nullptr);
    decimationFilter = librealsense.rs2_create_decimation_filter_block(
      ffi.nullptr,
    );
    thresholdFilter = librealsense.rs2_create_threshold(ffi.nullptr);
    temporalFilter = librealsense.rs2_create_temporal_filter_block(ffi.nullptr);
    // Decimation filter (magnitude: 3)
    librealsense.rs2_set_option(
      decimationFilter.cast<rs2_options>(),
      rs2_option.RS2_OPTION_FILTER_MAGNITUDE,
      3,
      ffi.nullptr,
    );
    // Threshold filter (min: 0.1, max: 4)
    librealsense.rs2_set_option(
      thresholdFilter.cast<rs2_options>(),
      rs2_option.RS2_OPTION_MIN_DISTANCE,
      0.1,
      ffi.nullptr,
    );
    librealsense.rs2_set_option(
      thresholdFilter.cast<rs2_options>(),
      rs2_option.RS2_OPTION_MAX_DISTANCE,
      5,
      ffi.nullptr,
    );
    // Temporal filter (alpha: 0.4, delta: 20)
    librealsense.rs2_set_option(
      temporalFilter.cast<rs2_options>(),
      rs2_option.RS2_OPTION_FILTER_SMOOTH_ALPHA,
      0.4,
      ffi.nullptr,
    );
    librealsense.rs2_set_option(
      temporalFilter.cast<rs2_options>(),
      rs2_option.RS2_OPTION_FILTER_SMOOTH_DELTA,
      20,
      ffi.nullptr,
    );
    pointCloudQueue = librealsense.rs2_create_frame_queue(1, ffi.nullptr);
    depthAlign = librealsense.rs2_create_align(
      rs2_stream.RS2_STREAM_COLOR,
      ffi.nullptr,
    );
    depthAlignQueue = librealsense.rs2_create_frame_queue(1, ffi.nullptr);
    filterQueue = librealsense.rs2_create_frame_queue(1, ffi.nullptr);
    colorizer = librealsense.rs2_create_colorizer(ffi.nullptr);
    colorizerQueue = librealsense.rs2_create_frame_queue(1, ffi.nullptr);
  }

  @override
  void onData(VideoCommand data) {
    final details = data.details;
    if (details.status == CameraStatus.CAMERA_DISABLED) {
      librealsense.rs2_delete_frame_queue(pointCloudQueue);
      librealsense.rs2_delete_frame_queue(filterQueue);
      librealsense.rs2_delete_frame_queue(depthAlignQueue);
      librealsense.rs2_delete_frame_queue(colorizerQueue);

      librealsense.rs2_delete_processing_block(pointCloud);
      librealsense.rs2_delete_processing_block(decimationFilter);
      librealsense.rs2_delete_processing_block(depthAlign);
      librealsense.rs2_delete_processing_block(colorizer);

      stop();
    }
    updateDetails(
      CameraDetails(
        streamWidth: details.streamWidth,
        streamHeight: details.streamHeight,
        quality: details.quality,
        fps: details.fps,
      ),
    );
  }

  /// Checks an [rs2_error] and will log and dispose of it if there is one present
  ///
  /// Returns true if there is an error, false otherwise
  bool checkError(
    ffi.Pointer<ffi.Pointer<rs2_error>> error, {
    CameraStatus statusIfError = CameraStatus.CAMERA_DISCONNECTED,
  }) {
    if (error.value == ffi.nullptr) {
      return false;
    }

    final type = librealsense.rs2_get_librealsense_exception_type(error.value);

    sendLog(
      Level.error,
      "RealSense Error ${librealsense.rs2_exception_type_to_string(type).toDartString()}",
      body: librealsense.rs2_get_error_message(error.value).toDartString(),
    );

    librealsense.rs2_free_error(error.value);
    calloc.free(error);

    updateDetails(CameraDetails(status: statusIfError));
    stop();

    return true;
  }

  /// Extracts a depth frame from an [rs2_frame]
  ///
  /// This assumes that [frameset] is a composite frame, and has embedded frames within it
  ffi.Pointer<rs2_frame> getDepthFrame(ffi.Pointer<rs2_frame> frameset) {
    final frameCount = librealsense.rs2_embedded_frames_count(
      frameset,
      ffi.nullptr,
    );

    for (int i = 0; i < frameCount; i++) {
      final frame = librealsense.rs2_extract_frame(frameset, i, ffi.nullptr);
      final isDepth = librealsense.rs2_is_frame_extendable_to(
        frame,
        rs2_extension.RS2_EXTENSION_DEPTH_FRAME,
        ffi.nullptr,
      );

      if (isDepth != 0) {
        return frame;
      }
      librealsense.rs2_release_frame(frame);
    }

    return ffi.nullptr;
  }

  /// Extracts an RGB frame from an [rs2_frame]
  ///
  /// This assumes that [frameset] is a composite frame, and has embedded frames within it
  ffi.Pointer<rs2_frame> getRGBFrame(ffi.Pointer<rs2_frame> frameset) {
    final frameCount = librealsense.rs2_embedded_frames_count(
      frameset,
      ffi.nullptr,
    );

    for (int i = 0; i < frameCount; i++) {
      final frame = librealsense.rs2_extract_frame(frameset, i, ffi.nullptr);
      final isDepth = librealsense.rs2_is_frame_extendable_to(
        frame,
        rs2_extension.RS2_EXTENSION_DEPTH_FRAME,
        ffi.nullptr,
      );
      if (isDepth == 0) {
        return frame;
      }
      librealsense.rs2_release_frame(frame);
    }

    return ffi.nullptr;
  }

  @override
  void initCamera() {
    final error = calloc<ffi.Pointer<rs2_error>>();

    final context = librealsense.rs2_create_context(RS2_API_VERSION, error);

    if (checkError(error)) return;

    final deviceList = librealsense.rs2_query_devices(context, error);

    if (checkError(error)) return;

    final devicesCount = librealsense.rs2_get_device_count(deviceList, error);

    if (checkError(error)) return;

    if (devicesCount == 0) {
      sendLog(Level.warning, "No Realsense Devices found");
      updateDetails(CameraDetails(status: CameraStatus.CAMERA_DISCONNECTED));
      librealsense.rs2_delete_device_list(deviceList);

      librealsense.rs2_free_error(error.value);
      calloc.free(error);

      stop();
      return;
    } else if (devicesCount > 1) {
      updateDetails(CameraDetails(status: CameraStatus.CAMERA_DISCONNECTED));

      sendLog(Level.error, "Too many realsense devices found: $devicesCount");
      librealsense.rs2_delete_device_list(deviceList);

      librealsense.rs2_free_error(error.value);
      calloc.free(error);

      stop();
      return;
    }

    device = librealsense.rs2_create_device(deviceList, 0, error);

    librealsense.rs2_delete_device_list(deviceList);

    if (checkError(error)) return;

    final name = librealsense.rs2_get_device_info(
      device,
      rs2_camera_info.RS2_CAMERA_INFO_NAME,
      error,
    );

    if (checkError(error)) return;

    final serialNumber = librealsense.rs2_get_device_info(
      device,
      rs2_camera_info.RS2_CAMERA_INFO_SERIAL_NUMBER,
      error,
    );

    if (checkError(error)) return;

    final firmwareVersion = librealsense.rs2_get_device_info(
      device,
      rs2_camera_info.RS2_CAMERA_INFO_FIRMWARE_VERSION,
      error,
    );

    if (checkError(error)) return;

    sendLog(
      Level.info,
      "Connected to Realsense Device 0",
      body:
          "Name: ${name.toDartString()}\nSerial: ${serialNumber.toDartString()}\nFirmware Version: ${firmwareVersion.toDartString()}",
    );

    pipeline = librealsense.rs2_create_pipeline(context, error);

    if (checkError(error)) return;

    config = librealsense.rs2_create_config(error);

    if (checkError(error)) return;

    librealsense.rs2_config_enable_stream(
      config,
      rs2_stream.RS2_STREAM_DEPTH,
      -1,
      640,
      480,
      rs2_format.RS2_FORMAT_ANY,
      0,
      error,
    );

    if (checkError(error)) return;

    librealsense.rs2_config_enable_stream(
      config,
      rs2_stream.RS2_STREAM_COLOR,
      -1,
      640,
      480,
      rs2_format.RS2_FORMAT_BGR8,
      0,
      error,
    );

    if (checkError(error)) return;

    pipelineProfile = librealsense.rs2_pipeline_start_with_config(
      pipeline,
      config,
      error,
    );

    if (checkError(error)) return;

    final frame = librealsense.rs2_pipeline_wait_for_frames(
      pipeline,
      RS2_DEFAULT_TIMEOUT,
      error,
    );

    if (checkError(error, statusIfError: CameraStatus.CAMERA_NOT_RESPONDING)) {
      return;
    }

    final depthFrame = getDepthFrame(frame);
    final colorFrame = getRGBFrame(frame);

    if (depthFrame == ffi.nullptr || colorFrame == ffi.nullptr) {
      if (depthFrame != ffi.nullptr) {
        librealsense.rs2_release_frame(depthFrame);
      }
      if (colorFrame != ffi.nullptr) {
        librealsense.rs2_release_frame(colorFrame);
      }
      librealsense.rs2_release_frame(frame);

      updateDetails(CameraDetails(status: CameraStatus.CAMERA_NOT_RESPONDING));

      librealsense.rs2_free_error(error.value);
      calloc.free(error);

      stop();
      return;
    }

    final depthWidth = librealsense.rs2_get_frame_width(depthFrame, error);
    final depthHeight = librealsense.rs2_get_frame_height(depthFrame, error);

    if (checkError(error, statusIfError: CameraStatus.CAMERA_NOT_RESPONDING)) {
      librealsense.rs2_release_frame(depthFrame);
      librealsense.rs2_release_frame(colorFrame);
      librealsense.rs2_release_frame(frame);
      return;
    }

    depthResolution = (width: depthWidth, height: depthHeight);

    final rgbWidth = librealsense.rs2_get_frame_width(colorFrame, error);
    final rgbHeight = librealsense.rs2_get_frame_height(colorFrame, error);

    if (checkError(error, statusIfError: CameraStatus.CAMERA_NOT_RESPONDING)) {
      librealsense.rs2_release_frame(depthFrame);
      librealsense.rs2_release_frame(colorFrame);
      librealsense.rs2_release_frame(frame);
      return;
    }

    rgbResolution = (width: rgbWidth, height: rgbHeight);

    librealsense.rs2_release_frame(depthFrame);
    librealsense.rs2_release_frame(colorFrame);
    librealsense.rs2_release_frame(frame);

    librealsense.rs2_start_processing_queue(
      pointCloud,
      pointCloudQueue,
      ffi.nullptr,
    );
    librealsense.rs2_start_processing_queue(
      decimationFilter,
      filterQueue,
      ffi.nullptr,
    );
    librealsense.rs2_start_processing_queue(
      thresholdFilter,
      filterQueue,
      ffi.nullptr,
    );
    librealsense.rs2_start_processing_queue(
      temporalFilter,
      filterQueue,
      ffi.nullptr,
    );
    librealsense.rs2_start_processing_queue(
      depthAlign,
      depthAlignQueue,
      ffi.nullptr,
    );
    librealsense.rs2_start_processing_queue(
      colorizer,
      colorizerQueue,
      ffi.nullptr,
    );

    updateDetails(CameraDetails(status: CameraStatus.CAMERA_ENABLED));
    librealsense.rs2_free_error(error.value);
    calloc.free(error);
  }

  @override
  void disposeCamera() {
    releaseNative();
  }

  /// Releases all native memory held by the isolate
  void releaseNative() {
    if (pipelineProfile != ffi.nullptr) {
      librealsense.rs2_delete_pipeline_profile(pipelineProfile);
      pipelineProfile = ffi.nullptr;
    }
    if (config != ffi.nullptr) {
      librealsense.rs2_delete_config(config);
      config = ffi.nullptr;
    }
    if (pipeline != ffi.nullptr) {
      librealsense.rs2_delete_pipeline(pipeline);
      pipeline = ffi.nullptr;
    }
    if (device != ffi.nullptr) {
      librealsense.rs2_delete_device(device);
    }
    if (context != ffi.nullptr) {
      librealsense.rs2_delete_context(context);
    }
  }

  @override
  Future<void> sendFrames() async {
    if (pipelineProfile == ffi.nullptr ||
        device == ffi.nullptr ||
        depthResolution == null) {
      return;
    }

    return using((Arena arena) async {
      final outputFrame = arena<ffi.Pointer<rs2_frame>>();

      final success = librealsense.rs2_pipeline_poll_for_frames(
        pipeline,
        outputFrame,
        ffi.nullptr,
      );

      if (success != 1) {
        return;
      }

      final processingFutures = <Future<void>>[];

      final depthFrame = getDepthFrame(outputFrame.value);

      if (depthFrame != ffi.nullptr) {
        processingFutures.add(
          Future(() async {
            await Future.wait([
              sendDepthFrame(depthFrame, arena),
              // processDepthPointCloud(depthFrame, arena),
            ]);
            librealsense.rs2_release_frame(depthFrame);
          }),
        );
      }

      final rgbFrame = getRGBFrame(outputFrame.value);

      if (rgbFrame != ffi.nullptr) {
        processingFutures.add(
          Future(() async {
            await sendRgbFrame(rgbFrame);
            librealsense.rs2_release_frame(rgbFrame);
          }),
        );
      }

      await Future.wait(processingFutures);

      fpsCount++;

      librealsense.rs2_release_frame(outputFrame.value);
    });
  }

  /// Processes, colorizes, and sends a depth frame
  ///
  /// The [rs2_frame] passed into this function will not be disposed
  /// inside of the method, after calling this method, [frame] should
  /// be disposed manually
  Future<void> sendDepthFrame(
    ffi.Pointer<rs2_frame> frame,
    ffi.Allocator arena,
  ) async {
    if (depthResolution == null) {
      return;
    }
    librealsense.rs2_frame_add_ref(frame, ffi.nullptr);
    librealsense.rs2_process_frame(depthAlign, frame, ffi.nullptr);

    final alignedOutput = arena<ffi.Pointer<rs2_frame>>();
    if (librealsense.rs2_poll_for_frame(
          depthAlignQueue,
          alignedOutput,
          ffi.nullptr,
        ) ==
        0) {
      sendLog(Level.error, "Could not align depth frame.");
      return;
    }

    librealsense.rs2_frame_add_ref(alignedOutput.value, ffi.nullptr);
    librealsense.rs2_process_frame(colorizer, alignedOutput.value, ffi.nullptr);

    final colorizedOutput = arena<ffi.Pointer<rs2_frame>>();

    if (librealsense.rs2_poll_for_frame(
          colorizerQueue,
          colorizedOutput,
          ffi.nullptr,
        ) ==
        0) {
      sendLog(Level.error, "Could not colorize depth frame.");
      librealsense.rs2_release_frame(alignedOutput.value);
      return;
    }

    final colorizedFrame = colorizedOutput.value;
    final colorizedLength = librealsense.rs2_get_frame_data_size(
      colorizedFrame,
      ffi.nullptr,
    );
    final colorizedData =
        librealsense
            .rs2_get_frame_data(colorizedFrame, ffi.nullptr)
            .cast<ffi.Uint8>();

    final colorizedImage = colorizedData.toOpenCVMat(
      depthResolution!,
      length: colorizedLength,
    );

    final colorizedJpeg = colorizedImage.encodeJpg(quality: details.quality);

    if (colorizedJpeg == null) {
      sendLog(LogLevel.warning, "Could not encode colorized frame");
    } else {
      sendFrame(colorizedJpeg);
    }
    colorizedImage.dispose();
    librealsense.rs2_release_frame(alignedOutput.value);
    librealsense.rs2_release_frame(colorizedFrame);
  }

  /// Transforms a depth frame into a 3d pointcloud
  ///
  /// This will send the point cloud to the parent isolate in the form of a [PointCloudPayload]
  ///
  /// The [rs2_frame] passed into this function will not be disposed
  /// inside of the method, after calling this method, [frame] should
  /// be disposed manually
  Future<void> processDepthPointCloud(
    ffi.Pointer<rs2_frame> frame,
    ffi.Allocator arena,
  ) async {
    librealsense.rs2_frame_add_ref(frame, ffi.nullptr);
    librealsense.rs2_process_frame(decimationFilter, frame, ffi.nullptr);

    final decimationOutput = arena<ffi.Pointer<rs2_frame>>();

    if (librealsense.rs2_poll_for_frame(
          filterQueue,
          decimationOutput,
          ffi.nullptr,
        ) ==
        0) {
      sendLog(Level.error, "Could not apply decimation filter");
      return;
    }

    librealsense.rs2_frame_add_ref(decimationOutput.value, ffi.nullptr);
    librealsense.rs2_process_frame(
      thresholdFilter,
      decimationOutput.value,
      ffi.nullptr,
    );

    final thresholdOutput = arena<ffi.Pointer<rs2_frame>>();

    if (librealsense.rs2_poll_for_frame(
          filterQueue,
          thresholdOutput,
          ffi.nullptr,
        ) ==
        0) {
      sendLog(Level.error, "Could not apply threshold filter");
      librealsense.rs2_release_frame(decimationOutput.value);
      return;
    }

    librealsense.rs2_frame_add_ref(thresholdOutput.value, ffi.nullptr);
    librealsense.rs2_process_frame(
      temporalFilter,
      thresholdOutput.value,
      ffi.nullptr,
    );

    final temporalOutput = arena<ffi.Pointer<rs2_frame>>();
    if (librealsense.rs2_poll_for_frame(
          filterQueue,
          temporalOutput,
          ffi.nullptr,
        ) ==
        0) {
      sendLog(Level.error, "Could not apply temporal filter");
      librealsense.rs2_release_frame(decimationOutput.value);
      librealsense.rs2_release_frame(thresholdOutput.value);
      return;
    }

    librealsense.rs2_process_frame(
      pointCloud,
      temporalOutput.value,
      ffi.nullptr,
    );

    final pointCloudOutput = arena<ffi.Pointer<rs2_frame>>();

    if (librealsense.rs2_poll_for_frame(
          pointCloudQueue,
          pointCloudOutput,
          ffi.nullptr,
        ) ==
        0) {
      sendLog(Level.error, "Could not process point cloud");
      librealsense.rs2_release_frame(decimationOutput.value);
      librealsense.rs2_release_frame(thresholdOutput.value);
      librealsense.rs2_release_frame(temporalOutput.value);
      return;
    }

    final points = <Coordinates>[];

    final vertices = librealsense.rs2_get_frame_vertices(
      pointCloudOutput.value,
      ffi.nullptr,
    );
    final verticesLength = librealsense.rs2_get_frame_points_count(
      pointCloudOutput.value,
      ffi.nullptr,
    );

    for (int i = 0; i < verticesLength; i += 2) {
      final x = vertices[i].xyz[0];
      final y = vertices[i].xyz[1];
      final z = vertices[i].xyz[2];

      if (x.abs() == 0 || z.abs() == 0) {
        continue;
      }

      if ((y - 0.1).abs() > 0.1) {
        continue;
      }

      points.add(Coordinates(x: x, y: y, z: z));
    }

    double distance(Coordinates coordinates) =>
        sqrt(pow(coordinates.x, 2) + pow(coordinates.z, 2));

    points.sort((a, b) => distance(a).compareTo(distance(b)));

    sendToParent(
      PointCloudPayload(points.sublist(0, min(points.length, 3500))),
    );

    librealsense.rs2_release_frame(decimationOutput.value);
    librealsense.rs2_release_frame(thresholdOutput.value);
    librealsense.rs2_release_frame(temporalOutput.value);
    librealsense.rs2_release_frame(pointCloudOutput.value);
  }

  /// Processes and sends an rgb frame
  ///
  /// The [rs2_frame] passed into this function will not be disposed
  /// inside of the method, after calling this method, [frame] should
  /// be disposed manually
  Future<void> sendRgbFrame(ffi.Pointer<rs2_frame> frame) async {
    if (rgbResolution == null) {
      return;
    }
    final rgbLength = librealsense.rs2_get_frame_data_size(frame, ffi.nullptr);
    final rgbData =
        librealsense.rs2_get_frame_data(frame, ffi.nullptr).cast<ffi.Uint8>();

    final rgbImage = rgbData.toOpenCVMat(rgbResolution!, length: rgbLength);

    final jpegImage = rgbImage.encodeJpg(quality: details.quality);

    if (jpegImage == null) {
      sendLog(LogLevel.debug, "Could not encode RGB frame");
    } else {
      final newDetails = details.deepCopy()..name = CameraName.ROVER_FRONT;
      sendFrame(jpegImage, detailsOverride: newDetails);
    }
    rgbImage.dispose();
  }
}
