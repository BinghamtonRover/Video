import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

// Processes a simple HTTP GET request using a native HTTP library that
// processes the request on a background thread.
Future<String> httpGet(String uri) async {
  final uriPointer = uri.toNativeUtf8();

  // Create the NativeCallable.listener.
  final completer = Completer<String>();
  late final NativeCallable<NativeHttpCallback> callback;
  void onResponse(Pointer<Utf8> responsePointer) {
    completer.complete(responsePointer.toDartString());
    calloc.free(responsePointer);
    calloc.free(uriPointer);

    // Remember to close the NativeCallable once the native API is
    // finished with it, otherwise this isolate will stay alive
    // indefinitely.
    callback.close();
  }
  callback = NativeCallable<NativeHttpCallback>.listener(onResponse);

  // Invoke the native HTTP API. Our example HTTP library processes our
  // request on a background thread, and calls the callback on that same
  // thread when it receives the response.
  nativeHttpGet(uriPointer, callback.nativeFunction);

  return completer.future;
}

// Load the native functions from a DynamicLibrary.
final DynamicLibrary dylib = DynamicLibrary.process();
typedef NativeHttpCallback = Void Function(Pointer<Utf8>);

typedef HttpGetFunction = void Function(
    Pointer<Utf8>, Pointer<NativeFunction<NativeHttpCallback>>);
typedef HttpGetNativeFunction = Void Function(
    Pointer<Utf8>, Pointer<NativeFunction<NativeHttpCallback>>);
final nativeHttpGet =
    dylib.lookupFunction<HttpGetNativeFunction, HttpGetFunction>(
        'http_get');