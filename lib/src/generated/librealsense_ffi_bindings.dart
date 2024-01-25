// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
// ignore_for_file: type=lint
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart' as pkg_ffi;

/// Bindings for the RealSense SDK.
///
/// Regenerate bindings with `dart run ffigen --config ffigen.yaml -v severe`.
///
class LibRealSenseBindings {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  LibRealSenseBindings(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  LibRealSenseBindings.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  /// Initialization
  ffi.Pointer<NativeRealSense> RealSense_create() {
    return _RealSense_create();
  }

  late final _RealSense_createPtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<NativeRealSense> Function()>>(
          'RealSense_create');
  late final _RealSense_create = _RealSense_createPtr.asFunction<
      ffi.Pointer<NativeRealSense> Function()>();

  void RealSense_free(
    ffi.Pointer<NativeRealSense> ptr,
  ) {
    return _RealSense_free(
      ptr,
    );
  }

  late final _RealSense_freePtr = _lookup<
          ffi.NativeFunction<ffi.Void Function(ffi.Pointer<NativeRealSense>)>>(
      'RealSense_free');
  late final _RealSense_free = _RealSense_freePtr.asFunction<
      void Function(ffi.Pointer<NativeRealSense>)>();

  int RealSense_init(
    ffi.Pointer<NativeRealSense> ptr,
  ) {
    return _RealSense_init(
      ptr,
    );
  }

  late final _RealSense_initPtr = _lookup<
          ffi.NativeFunction<ffi.Int32 Function(ffi.Pointer<NativeRealSense>)>>(
      'RealSense_init');
  late final _RealSense_init = _RealSense_initPtr.asFunction<
      int Function(ffi.Pointer<NativeRealSense>)>();

  ffi.Pointer<pkg_ffi.Utf8> RealSense_getDeviceName(
    ffi.Pointer<NativeRealSense> ptr,
  ) {
    return _RealSense_getDeviceName(
      ptr,
    );
  }

  late final _RealSense_getDeviceNamePtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<pkg_ffi.Utf8> Function(
              ffi.Pointer<NativeRealSense>)>>('RealSense_getDeviceName');
  late final _RealSense_getDeviceName = _RealSense_getDeviceNamePtr.asFunction<
      ffi.Pointer<pkg_ffi.Utf8> Function(ffi.Pointer<NativeRealSense>)>();

  BurtRsConfig RealSense_getDeviceConfig(
    ffi.Pointer<NativeRealSense> ptr,
  ) {
    return _RealSense_getDeviceConfig(
      ptr,
    );
  }

  late final _RealSense_getDeviceConfigPtr = _lookup<
          ffi
          .NativeFunction<BurtRsConfig Function(ffi.Pointer<NativeRealSense>)>>(
      'RealSense_getDeviceConfig');
  late final _RealSense_getDeviceConfig = _RealSense_getDeviceConfigPtr
      .asFunction<BurtRsConfig Function(ffi.Pointer<NativeRealSense>)>();

  /// Streams
  int RealSense_startStream(
    ffi.Pointer<NativeRealSense> ptr,
  ) {
    return _RealSense_startStream(
      ptr,
    );
  }

  late final _RealSense_startStreamPtr = _lookup<
          ffi.NativeFunction<ffi.Int32 Function(ffi.Pointer<NativeRealSense>)>>(
      'RealSense_startStream');
  late final _RealSense_startStream = _RealSense_startStreamPtr.asFunction<
      int Function(ffi.Pointer<NativeRealSense>)>();

  void RealSense_stopStream(
    ffi.Pointer<NativeRealSense> ptr,
  ) {
    return _RealSense_stopStream(
      ptr,
    );
  }

  late final _RealSense_stopStreamPtr = _lookup<
          ffi.NativeFunction<ffi.Void Function(ffi.Pointer<NativeRealSense>)>>(
      'RealSense_stopStream');
  late final _RealSense_stopStream = _RealSense_stopStreamPtr.asFunction<
      void Function(ffi.Pointer<NativeRealSense>)>();

  /// Frames
  ffi.Pointer<BurtRsFrames> RealSense_getFrames(
    ffi.Pointer<NativeRealSense> ptr,
  ) {
    return _RealSense_getFrames(
      ptr,
    );
  }

  late final _RealSense_getFramesPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<BurtRsFrames> Function(
              ffi.Pointer<NativeRealSense>)>>('RealSense_getFrames');
  late final _RealSense_getFrames = _RealSense_getFramesPtr.asFunction<
      ffi.Pointer<BurtRsFrames> Function(ffi.Pointer<NativeRealSense>)>();

  void BurtRsFrames_free(
    ffi.Pointer<BurtRsFrames> ptr,
  ) {
    return _BurtRsFrames_free(
      ptr,
    );
  }

  late final _BurtRsFrames_freePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<BurtRsFrames>)>>(
          'BurtRsFrames_free');
  late final _BurtRsFrames_free = _BurtRsFrames_freePtr.asFunction<
      void Function(ffi.Pointer<BurtRsFrames>)>();
}

abstract class BurtRsStatus {
  static const int BurtRsStatus_ok = 0;
  static const int BurtRsStatus_no_device = 1;
  static const int BurtRsStatus_too_many_devices = 2;
  static const int BurtRsStatus_resolution_unknown = 3;
  static const int BurtRsStatus_scale_unknown = 4;
}

final class BurtRsConfig extends ffi.Struct {
  @ffi.Int()
  external int width;

  @ffi.Int()
  external int height;

  @ffi.Float()
  external double scale;
}

final class BurtRsFrames extends ffi.Struct {
  external ffi.Pointer<ffi.Uint16> depth_frame;

  external ffi.Pointer<ffi.Uint8> colorized_frame;

  @ffi.Int()
  external int depth_length;

  @ffi.Int()
  external int colorized_length;

  external ffi.Pointer<ffi.Void> frame_pointer;
}

/// A fake ("opaque") C-friendly struct that we'll use a pointer to.
/// This pointer will actually represent the RealSense class in C++
final class NativeRealSense extends ffi.Opaque {}
