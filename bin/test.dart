// // ignore_for_file: avoid_print

// import "dart:ffi";
// import "package:typed_isolate/typed_isolate.dart";
// import "package:opencv_ffi/opencv_ffi.dart";

// class ImageData {
//   final int address;
//   final int length;
//   const ImageData({required this.address, required this.length});
// }

// class Parent extends IsolateParent<ImageData, void> {
//   @override
//   void onData(void data) { }

//   @override
//   Future<void> run() async {
//     print("Opening camera...");
//     final camera = Camera.fromIndex(0);
//     if (!camera.isOpened) {
//       print("Could not open camera");
//       return;
//     }
//     print("Camera opened");
//     for (int i = 0; i < 10; i++) {
//       final image = camera.getJpg();
//       if (image == null) {
//         print("Could not read frame");
//         continue;
//       }
//       final address = image.pointer.address;
//       final length = image.data.length;
//       print("Got an image at ($address) with $length bytes");
//       final data = ImageData(address: image.pointer.address, length: length);
//       send(data, 0);
//     }
//   }
// }

// class Child extends IsolateChild<void, ImageData> {
//   Child({required super.id});
  
//   @override
//   void onData(ImageData data) {
//     final pointer = Pointer.fromAddress(data.address).cast<Uint8>();
//     final image = OpenCVImage(pointer: pointer, length: data.length);
//     print("  Child received pointer ${image.pointer.address} w/ ${image.data.length} bytes");
//   }

//   @override
//   void run() { }
// }

// void main() async {
//   final parent = Parent();
//   print("Creating parent isolate... ");
//   final child = Child(id: 0);
//   final isolate = await parent.spawn(child);
//   print("Waiting for child to spawn...");
//   await Future<void>.delayed(const Duration(seconds: 1));
//   print("Running main isolate...");
//   await parent.run();
//   parent.close();
//   isolate.kill();
// }
