// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
// ignore_for_file: type=lint
import 'dart:ffi' as ffi;

/// Bindings for the RealSense SDK.
///
/// Regenerate bindings with `dart run ffigen --config ffigen.yaml -v severe`.
///
class LidarBinding {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  LidarBinding(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  LidarBinding.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  void updateLatestImage(
    ffi.Pointer<ffi.Void> apiHandle,
    ffi.Pointer<ffi.Void> pointCloudMsg,
  ) {
    return _updateLatestImage(
      apiHandle,
      pointCloudMsg,
    );
  }

  late final _updateLatestImagePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>)>>('updateLatestImage');
  late final _updateLatestImage = _updateLatestImagePtr.asFunction<
      void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>)>();

  Image getLatestImage() {
    return _getLatestImage();
  }

  late final _getLatestImagePtr =
      _lookup<ffi.NativeFunction<Image Function()>>('getLatestImage');
  late final _getLatestImage =
      _getLatestImagePtr.asFunction<Image Function()>();

  late final addresses = _SymbolAddresses(this);
}

class _SymbolAddresses {
  final LidarBinding _library;
  _SymbolAddresses(this._library);
  ffi.Pointer<
          ffi.NativeFunction<
              ffi.Void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>)>>
      get updateLatestImage => _library._updateLatestImagePtr;
}

final class Image extends ffi.Struct {
  @ffi.Uint64()
  external int size;

  @ffi.Uint64()
  external int capacity;
}
