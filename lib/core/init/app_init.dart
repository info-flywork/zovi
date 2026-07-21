import 'package:shared_preferences/shared_preferences.dart';
import 'package:zovi/core/di/injection.dart';

abstract final class AppInit {
  static Future<void> init() async {
    await SharedPreferences.getInstance();
    await configureDependencies();
  }
}
