// ignore_for_file: avoid_print

import "dart:io";
import "dart:typed_data";

import "package:burt_network/udp.dart";

void main() async {
	final socket = UdpSocket(port: 8020);
	await socket.init();
	socket.stream.listen(temp);
	while (true) {
		await Future<void>.delayed(const Duration(seconds: 1));
	}
}

void temp(Datagram packet) {
	final data = Float64List.sublistView(packet.data);
	final processed = [
		for (final number in data) 
			if (!number.isNaN)
				number.toStringAsFixed(3),
	];
	print("------------------------------------------");
	print(processed);
}
