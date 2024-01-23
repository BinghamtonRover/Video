Future<void> main() async {
	print("1");
	await Future<void>.delayed(Duration(days: 3));
	print("2");
}
