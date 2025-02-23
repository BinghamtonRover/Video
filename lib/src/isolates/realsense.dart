import "dart:ffi" as ffi;
import "dart:io";

import "package:burt_network/burt_network.dart";
import "package:dartcv4/dartcv.dart";
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
  ({int width, int height})? depthResolution;

  /// The resolution in pixels of the RGB frame
  ({int width, int height})? rgbResolution;

  /// Default constructor for the Realsense Isolate
  ///
  /// This will initialize the fields for alignmenet and processing queues,
  /// which do not rely on a specific device
  RealsenseIsolate({required super.details}) {
    depthAlign = librealsense.rs2_create_align(
      rs2_stream.RS2_STREAM_COLOR,
      ffi.nullptr,
    );
    depthAlignQueue = librealsense.rs2_create_frame_queue(1, ffi.nullptr);
    colorizer = librealsense.rs2_create_colorizer(ffi.nullptr);
    colorizerQueue = librealsense.rs2_create_frame_queue(1, ffi.nullptr);
  }

  @override
  void onData(VideoCommand data) {
    final details = data.details;
    if (details.status == CameraStatus.CAMERA_DISABLED) {
      librealsense.rs2_delete_frame_queue(depthAlignQueue);
      librealsense.rs2_delete_frame_queue(colorizerQueue);
      librealsense.rs2_delete_processing_block(depthAlign);
      librealsense.rs2_delete_processing_block(colorizer);

      disposeCamera();
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
      "RealSense Error ${librealsense.rs2_exception_type_to_string(type)}",
      body: librealsense.rs2_get_error_message(error.value).toDartString(),
    );
    releaseNative();
    calloc.free(error);

    updateDetails(CameraDetails(status: statusIfError));

    return true;
  }

  /// Extracts a depth frame from an [rs2_frame]
  ///
  /// This assumes that the [frameset] is a composite frame, and has embedded frames within it
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
  /// This assumes that the [frameset] is a composite frame, and has embedded frames within it
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
      sendLog(Level.warning, "No Realsense Devices found!");
      updateDetails(CameraDetails(status: CameraStatus.CAMERA_DISCONNECTED));
      librealsense.rs2_delete_device_list(deviceList);
      return;
    } else if (devicesCount > 1) {
      sendLog(Level.error, "Too many realsense devices found: $devicesCount");
      librealsense.rs2_delete_device_list(deviceList);
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

    if (checkError(error, statusIfError: CameraStatus.CAMERA_NOT_RESPONDING) ||
        depthFrame == ffi.nullptr ||
        colorFrame == ffi.nullptr) {
      if (depthFrame != ffi.nullptr) {
        librealsense.rs2_release_frame(depthFrame);
      }
      if (colorFrame != ffi.nullptr) {
        librealsense.rs2_release_frame(colorFrame);
      }
      librealsense.rs2_release_frame(frame);
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

    final outputFrame = calloc<ffi.Pointer<rs2_frame>>();

    final success = librealsense.rs2_pipeline_poll_for_frames(
      pipeline,
      outputFrame,
      ffi.nullptr,
    );

    if (success != 1) {
      calloc.free(outputFrame);
      return;
    }

    final depthFrame = getDepthFrame(outputFrame.value);

    if (depthFrame != ffi.nullptr) {
      await sendDepthFrame(depthFrame);
    }

    final rgbFrame = getRGBFrame(outputFrame.value);

    if (rgbFrame != ffi.nullptr) {
      await sendRgbFrame(rgbFrame);
    }

    fpsCount++;

    librealsense.rs2_release_frame(depthFrame);
    librealsense.rs2_release_frame(rgbFrame);
    librealsense.rs2_release_frame(outputFrame.value);

    calloc.free(outputFrame);
  }

  /// Processes, colorizes, and sends a depth frame
  ///
  /// The [rs2_frame] passed into this function will not be disposed
  /// inside of the method, after calling this method, [frame] should
  /// be disposed manually
  Future<void> sendDepthFrame(ffi.Pointer<rs2_frame> frame) async {
    librealsense.rs2_frame_add_ref(frame, ffi.nullptr);
    librealsense.rs2_process_frame(depthAlign, frame, ffi.nullptr);

    final alignedOutput = calloc<ffi.Pointer<rs2_frame>>();
    if (librealsense.rs2_poll_for_frame(
          depthAlignQueue,
          alignedOutput,
          ffi.nullptr,
        ) ==
        0) {
      sendLog(Level.error, "Could not align depth frame.");
      calloc.free(alignedOutput);
      return;
    }

    librealsense.rs2_frame_add_ref(alignedOutput.value, ffi.nullptr);
    librealsense.rs2_process_frame(colorizer, alignedOutput.value, ffi.nullptr);

    final colorizedOutput = calloc<ffi.Pointer<rs2_frame>>();

    if (librealsense.rs2_poll_for_frame(
          colorizerQueue,
          colorizedOutput,
          ffi.nullptr,
        ) ==
        0) {
      sendLog(Level.error, "Could not colorize depth frame.");
      librealsense.rs2_release_frame(alignedOutput.value);
      calloc.free(alignedOutput);
      calloc.free(colorizedOutput);
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
    calloc.free(alignedOutput);
    calloc.free(colorizedOutput);
  }

  /// Processes and sends an rgb frame
  ///
  /// The [rs2_frame] passed into this function will not be disposed
  /// inside of the method, after calling this method, [frame] should
  /// be disposed manually
  Future<void> sendRgbFrame(ffi.Pointer<rs2_frame> frame) async {
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
