import 'package:flutter/material.dart';
import 'package:zovi/app.dart';
import 'package:zovi/core/init/app_init.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInit.init();
  runApp(const ZoviApp());
}
