import "package:burt_network/logging.dart";
import "package:video/video.dart";

void main() async{
  BurtLogger.level = LogLevel.info;  
  await collection.init();
}
