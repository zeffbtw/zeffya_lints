import 'dart:isolate';

import 'package:analyzer_plugin/starter.dart';
import 'package:zeffya_lints/src/plugin.dart';

void main(List<String> args, SendPort sendPort) {
  ServerPluginStarter(ZeffyaLintsPlugin()).start(sendPort);
}
