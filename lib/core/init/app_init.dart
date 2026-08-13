import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zovi/core/deep_link/deep_link_service.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/network/dio_client.dart';
import 'package:zovi/core/notifications/notification_inbox_watcher.dart';
import 'package:zovi/core/notifications/chat_notification_watcher.dart';
import 'package:zovi/core/push/push_notification_service.dart';
import 'package:zovi/core/router/app_router.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/firebase_options.dart';

abstract final class AppInit {
  static Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await SharedPreferences.getInstance();
    await configureDependencies();
    await getIt<DeepLinkService>().start();
    final push = getIt<PushNotificationService>();
    await push.start();
    getIt<AuthRepository>().attachPushService(push);

    final inbox = getIt<NotificationInboxWatcher>()..start();
    push.attachSeenSink(inbox.markSeen);

    final chatWatcher = getIt<ChatNotificationWatcher>()..start();
    push.attachChatSeenSink(chatWatcher.markSeen);
    inbox.attachChatSeenSink(chatWatcher.markSeen);
    chatWatcher.attachInboxBannerSink(inbox.markChatBannerSeen);

    var endingSession = false;
    DioClient.onSessionExpired = () async {
      if (endingSession) return;
      endingSession = true;
      try {
        await getIt<AuthRepository>().logout();
        getIt<UserRepository>().clearSessionCache();
        await resetUserScopedSingletons();
        AppRouter.router.go(RoutePaths.onboarding.path);
      } catch (_) {
        AppRouter.router.go(RoutePaths.onboarding.path);
      } finally {
        endingSession = false;
      }
    };
  }
}
