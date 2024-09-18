import "dart:ffi";
// import "dart:io";
// import "dart:typed_data";
import "../generated/lidar_ffi_bindings.dart";
import "package:ffi/ffi.dart";
import "package:opencv_ffi/opencv_ffi.dart";

const cliArgs = "hostname:=169.254.166.55";
const launchFile = "lidar.launch";

/// An ffi implementation of SICK Lidar API
class LidarFFI {
  final LidarBindings bindings;
  late Pointer<Void> _handle;

  LidarFFI() : bindings = LidarBindings(DynamicLibrary.open("lidar.dll"));

  bool init() => using((arena) {
    _handle = bindings.SickScanApiCreate(0, nullptr);
    // bindings.SickScanApiInitByLaunchfile(_handle, filename);
    // final array = arena<Char>();
    final argsPtr = arena<Pointer<Char>>(3);
    argsPtr[0] = "lidar.dart".toNativeUtf8(allocator: arena).cast<Char>();
    argsPtr[1] = launchFile.toNativeUtf8(allocator: arena).cast<Char>();
    argsPtr[2] = cliArgs.toNativeUtf8(allocator: arena).cast<Char>();
    for (int i = 0; i < 3; i++) {
      final element = argsPtr[i].cast<Utf8>();
      final str = element.toDartString();
      // print("Arg $i is $str");
    }
    bindings.SickScanApiInitByCli(_handle, 3, argsPtr);
    // print("Done init");
    return true;
  });

  void dispose() {
    bindings.SickScanApiClose(_handle);
    bindings.SickScanApiRelease(_handle);
  }

  /// Converts a [SickScanPointCloudMsg] into a single [OpenCVImage]
  Future<OpenCVImage?> getOneImage() =>
    using((arena) async {
      final struct = arena<SickScanPointCloudMsgType>();
      //bindings.SickScanApiRegisterCartesianPointCloudMsg(_handle, struct);
      //final result = 
      bindings.SickScanApiWaitNextCartesianPointCloudMsg(_handle, struct, 3);
      
      // print(result);
      final length = struct.ref.data.size;
      // print(struct.ref.data.buffer.asTypedList(length));
      // print(struct.ref.fields.size); 
      final fieldBuffer = struct.ref.fields.buffer;
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
            pixels[3 * img_y * imgWidth + 3 * img_x + 0] = 255; // R
            pixels[3 * img_y * imgWidth + 3 * img_x + 1] = 255; // G
            pixels[3 * img_y * imgWidth + 3 * img_x + 2] = 255; // B
          }
        }
      }
      addCross(imgHeight, imgWidth, pixels);
      addHiddenArea(imgHeight, imgWidth, pixels);
      print("GOT THIS FAR");
      final mat = getMatrix(imgHeight, imgWidth, pixels);
      final jpeg = encodeJpg(mat);
      print("  IMAGE IS: $jpeg");
      if(jpeg == null){
        print("null image");
        return null;
      }
      return jpeg;
      //   await File("temp.jpg").writeAsBytes(jpeg.data);
      //   //jpeg.dispose();
      //   // const outputFileName = "test.jpg";
      // print("SOMEHOW GOT NOTHING");
      // return null;
      
      // print("${struct.ref.height} ${struct.ref.width}");

    }); 

    /// Add a red cross to the center of an image
    void addCross(int imgHeight, int imgWidth, Pointer<Uint8> pixels){
      final midx = imgWidth ~/ 2;
      final midy = imgHeight ~/ 2;
      for(var i = midx - 5; i <= midx + 5; i++){ // draw horizontal
        pixels[3 * midy * imgWidth + 3 * i + 0] = 255; // R
        pixels[3 * midy * imgWidth + 3 * i + 1] = 0; // G
        pixels[3 * midy * imgWidth + 3 * i + 2] = 0; // B
      }
      for(var i = midy - 5; i <= midy + 5; i++){  // draw vertical
        pixels[3 * i * imgWidth + 3 * midx + 0] = 255; // R
        pixels[3 * i * imgWidth + 3 * midx + 1] = 0; // G
        pixels[3 * i * imgWidth + 3 * midx + 2] = 0; // B
      }
    }

    /// Draws a triangle in the area behind lidar that doesn't include data
    void addHiddenArea(int imgHeight, int imgWidth, Pointer<Uint8> pixels){
      final increment = (imgHeight /~ 2) ~/ (imgWidth /~ 2);
      var xoff = 1;
      var y = imgHeight - 1;
      while(y < (imgHeight /~ 2)){
        for(var x = xoff; x < imgWidth - xoff; x++){
          pixels[3 * y * imgWidth + 3 * x + 0] = 140; // R
          pixels[3 * y * imgWidth + 3 * x + 1] = 140; // G
          pixels[3 * y * imgWidth + 3 * x + 2] = 140; // B
        }
        y++;
        xoff += increment;
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

// void main() async {
//   final sensor = LidarFFI();
//   print("Start init");
//   sensor.init();
//   // await Future<void>.delayed(Duration(seconds: 3));

//   print("Finished init");
//   while(true){
//     sensor.getOneImage();
//     await Future<void>.delayed(const Duration(seconds: 5));
//   }
//   await Future<void>.delayed(Duration(seconds: 10));
//   sensor.dispose();
//   print("Finished Program Execution");
//   // return;
// }
