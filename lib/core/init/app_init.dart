import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zovi/core/deep_link/deep_link_service.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/firebase_options.dart';

abstract final class AppInit {
  static Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await SharedPreferences.getInstance();
    await configureDependencies();
    await getIt<DeepLinkService>().start();
  }
}
