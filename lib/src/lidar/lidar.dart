import "dart:developer";
import "dart:ffi";

import "../generated/lidar_ffi_bindings.dart";
import "package:ffi/ffi.dart";
import "package:opencv_ffi/opencv_ffi.dart";

const cliArgs = "hostname:=169.254.166.55";
const launchFile = "lidar.launch";

typedef NativePointCloudMsgCallback = Void Function(Pointer<Void>, Pointer<SickScanPointCloudMsgType>);

/// An ffi implementation of SICK Lidar API
class LidarFFI {
  final LidarBindings bindings;
  late Pointer<Void> _handle;

  LidarFFI() : bindings = LidarBindings(DynamicLibrary.open("lidar.dll"));

  Future<bool> init() => using((arena) async {
    _handle = bindings.SickScanApiCreate(0, nullptr);
    // bindings.SickScanApiInitByLaunchfile(_handle, filename);
    // final array = arena<Char>();
    final argsPtr = arena<Pointer<Char>>(3);
    argsPtr[0] = "lidar.dart".toNativeUtf8(allocator: arena).cast<Char>();
    argsPtr[1] = launchFile.toNativeUtf8(allocator: arena).cast<Char>();
    argsPtr[2] = cliArgs.toNativeUtf8(allocator: arena).cast<Char>();

    final result = bindings.SickScanApiInitByCli(_handle, 3, argsPtr);

    late final NativeCallable<NativePointCloudMsgCallback> callback;
    // This is the actual callback function
    // TODO: need to make this do something
    // TODO: put somewhere else in class
    // TODO: Get rid of the yellow squigallys by fixing constraint problems
    void handler(SickScanApiHandle apiHandle, Pointer<SickScanPointCloudMsg> msg) {

      // Remember to close the NativeCallable once the native API is
      // finished with it, otherwise this isolate will stay alive
      // indefinitely.
      print("Recieved msg with size: ${msg.ref.height} x ${msg.ref.width}");
      callback.close();
    }
    callback = NativeCallable<NativePointCloudMsgCallback>.listener(handler);

    bindings.SickScanApiRegisterCartesianPointCloudMsg(_handle, callback.nativeFunction);
    
    await Future<void>.delayed(const Duration(seconds: 10));
    if(result != 0){
      print("Unable to initialize Sick Scan Lidar");
      return false;
    }
    print("finished init");
    return true;
  });

  void dispose() {
    bindings.SickScanApiClose(_handle);
    bindings.SickScanApiRelease(_handle);
  }

  /// Converts a [SickScanPointCloudMsg] into a single [OpenCVImage]
  Future<OpenCVImage?> getOneImage({double timeout = 5}) =>
    using((arena) async {
      final struct = arena<SickScanPointCloudMsgType>();
      final result = bindings.SickScanApiWaitNextCartesianPointCloudMsg(_handle, struct, timeout);
      await Future<void>.delayed(Duration(seconds: timeout.toInt()));
      
      if(result != 0){
        print("There was a problem calling SickScanApiWaitNextCartesianPointCloudMsg()");
        return null;
      }
      //final length = struct.ref.data.size;
      // print(struct.ref.data.buffer.asTypedList(length));
      // print(struct.ref.fields.size); 
      final fieldBuffer = struct.ref.fields.buffer;
      final data = struct.ref.data;
      print("capacity: ${data.capacity}, size: ${data.size}");
      int field_offset_x = -1, field_offset_y = -1, field_offset_z = -1, field_offset_intensity = -1;
      for(int i = 0; i < struct.ref.fields.size; i++){

        final name = fieldBuffer[i].name.toDartString();
        final datatype = SickScanNativeDataType.fromValue(fieldBuffer[i].datatype);
        //final value = fieldBuffer[i].offset;
            // print("a 1 [$name] $datatype $value");
            // print(name.length);
            // print(datatype == SickScanNativeDataType.SICK_SCAN_POINTFIELD_DATATYPE_FLOAT32);
        
        if(name == "x" && datatype == SickScanNativeDataType.SICK_SCAN_POINTFIELD_DATATYPE_FLOAT32){
          field_offset_x = fieldBuffer[i].offset;
          // print("  here x");
        } else if (name == "y" && datatype == SickScanNativeDataType.SICK_SCAN_POINTFIELD_DATATYPE_FLOAT32){
          field_offset_y = fieldBuffer[i].offset;
          // print("  here y");
        } else if (name == "z" && datatype == SickScanNativeDataType.SICK_SCAN_POINTFIELD_DATATYPE_FLOAT32){
          field_offset_z = fieldBuffer[i].offset;
          // print("  here z");
        } else if (name == "intensity" && datatype == SickScanNativeDataType.SICK_SCAN_POINTFIELD_DATATYPE_FLOAT32){
          field_offset_intensity = fieldBuffer[i].offset;
          // print("  here i");
        }
      }
      if(field_offset_x < 0 || field_offset_y < 0 || field_offset_z < 0) {print("fields wrong"); return null;}
      
      const imgWidth = 250 * 4;
      const imgHeight = 250 * 4;

      // uint8_t* pixels = (uint8_t*)calloc(3 * img_width * img_height, sizeof(uint8_t));
      final pixels = arena<Uint8>(3 * imgWidth * imgHeight);
      addHiddenArea(imgHeight, imgWidth, pixels);
      for (var row_idx = 0; row_idx < struct.ref.height; row_idx++){
          for (var col_idx = 0; col_idx < struct.ref.width; col_idx++){
              // Get cartesian point coordinates
              var polar_point_offset = row_idx * struct.ref.row_step + col_idx * struct.ref.point_step;
              var address = struct.ref.data.buffer.address + polar_point_offset + field_offset_x;
              final point_x = Pointer<Float>.fromAddress(address).value;
              address = struct.ref.data.buffer.address + polar_point_offset + field_offset_y;
              final point_y = Pointer<Float>.fromAddress(address).value;
              address = struct.ref.data.buffer.address + polar_point_offset + field_offset_z;
              final point_z = Pointer<Float>.fromAddress(address).value;
              double point_intensity = 0;
              if (field_offset_intensity >= 0){
                address = struct.ref.data.buffer.address + polar_point_offset + field_offset_intensity;
                point_intensity = Pointer<Float>.fromAddress(address).value;
              }
                  // print("a2.5");

          // Convert point coordinates in meter to image coordinates in pixel
          int img_x = (250.0 * (-point_y + 2.0)).toInt(); // img_x := -pointcloud.y
          int img_y = (250.0 * (-point_x + 2.0)).toInt(); // img_y := -pointcloud.x
          if (img_x >= 0 && img_x < imgWidth && img_y >= 0 && img_y < imgHeight) // point within the image area
          {
            pixels[3 * img_y * imgWidth + 3 * img_x + 0] = 0; // B
            pixels[3 * img_y * imgWidth + 3 * img_x + 1] = 255; // G
            pixels[3 * img_y * imgWidth + 3 * img_x + 2] = 255; // R
          }
        }
      }
      
      addCross(imgHeight, imgWidth, pixels);
      print("GOT THIS FAR");
      final mat = getMatrix(imgHeight, imgWidth, pixels);
      final jpeg = encodeJpg(mat);
      print("  IMAGE IS: $jpeg");
      if(jpeg == null){
        print("null image");
        return null;
      }
      bindings.SickScanApiFreePointCloudMsg(_handle, struct);
      return jpeg;
    }); 

    /// Add a red cross to the center of an image
    void addCross(int imgHeight, int imgWidth, Pointer<Uint8> pixels, {int thickness = 1}){
      final midx = imgWidth ~/ 2;
      final midy = imgHeight ~/ 2;
      for(var x = midx - 7; x <= midx + 7; x++){ // draw horizontal
        for(var y = midy - thickness; y < midy + thickness; y++){
          pixels[3 * y * imgWidth + 3 * x + 0] = 0; // B
          pixels[3 * y * imgWidth + 3 * x + 1] = 0; // G
          pixels[3 * y * imgWidth + 3 * x + 2] = 255; // R
        }
      }
      for(var y = midy - 7; y <= midy + 7; y++){  // draw vertical
        for(var x = midx - thickness; x < midx + thickness; x++){ 
          pixels[3 * y * imgWidth + 3 * x + 0] = 0; // B
          pixels[3 * y * imgWidth + 3 * x + 1] = 0; // G
          pixels[3 * y * imgWidth + 3 * x + 2] = 255; // R
        }
      }
    }

    /// Draws a triangle in the area behind lidar that doesn't include data
    void addHiddenArea(int imgHeight, int imgWidth, Pointer<Uint8> pixels){
      /// NEED IMAGE TO BE SQUARE FOR THIS TO WORK
      for(var y = imgHeight - 1; y > imgHeight ~/ 2; y--){
        for(var x = imgWidth - y; x < y; x++){
          pixels[3 * y * imgWidth + 3 * x + 0] = 130; // R
          pixels[3 * y * imgWidth + 3 * x + 1] = 130; // G
          pixels[3 * y * imgWidth + 3 * x + 2] = 130; // B
        }
      }
    }

}

/// Extension on Array<Char>
extension ToDartString on Array<Char> {
  /// Converts an [Array] of [Char] to a native dart [String]
  String toDartString({int length = 252}){
    var i = 0; 
    final buffer = StringBuffer();
    while(i < length) {
      if (String.fromCharCode(this[i]) == "\n" || this[i] == 0) break;
      buffer.writeCharCode(this[i]);
      i++;
    }
    return buffer.toString();
  }
}

void main() async {
  final sensor = LidarFFI();
  print("Start init");
  sensor.init();
  await Future<void>.delayed(const Duration(seconds: 10));
  print("Finished init");
  
  for(var i = 0; i < 5; i++){
    final image = await sensor.getOneImage();
    print(image);
    await Future<void>.delayed(const Duration(seconds: 5));
  }

  sensor.dispose();
  
  await Future<void>.delayed(Duration(seconds: 10));
  sensor.dispose();
  print("Finished Program Execution");
  return;
}