// ignore_for_file: avoid_print

import "package:typed_isolate/typed_isolate.dart";

class NumberSender extends IsolateParent<int, int> {
  @override
  Future<void> run() async {
    print("Opening parent...");
    print("Sending: 1");
    //send(1, "braces");
    send(1, "brackets");
    await Future<void>.delayed(const Duration(seconds: 1));

    print("Sending: 2");
    send(2, "brackets");
    //send(2, "braces");
    await Future<void>.delayed(const Duration(seconds: 1));

    print("Sending: 3");
    //send(3, "braces");
    send(3, "brackets");
    await Future<void>.delayed(const Duration(seconds: 1));
  }

  @override
  void onData(int data) => print("Got: $data");
}

class NumberConverter extends IsolateChild<int, int> {
  NumberConverter() : super(id: "brackets");
  
  @override
  void run() => print("Opening child...");

  @override
  void onData(int data) => send(data + 5);
}

class NumberConverter2 extends IsolateChild<String, int> {
  NumberConverter2() : super(id: "braces");

  @override
  void run() => print("Opening child...");

  @override
  void onData(int data) => send("{$data}");
}

void main() async {
  final parent = NumberSender();
  final isolate1 = await parent.spawn(NumberConverter());
  //final isolate2 = await parent.spawn(NumberConverter2());
  await Future<void>.delayed(const Duration(seconds: 1));
  await parent.run();
  isolate1.kill();
  //isolate2.kill();
  parent.close();
}