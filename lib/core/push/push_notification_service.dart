import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:zovi/core/chat/active_chat_tracker.dart';
import 'package:zovi/core/config/onesignal_config.dart';
import 'package:zovi/core/in_app_notification/app_in_app_notification.dart';
import 'package:zovi/core/in_app_notification/in_app_notification_data.dart';
import 'package:zovi/core/notifications/chat_notification_watcher.dart';
import 'package:zovi/core/router/app_router.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/utils/navigation/open_story_by_id.dart';
import 'package:zovi/presentation/chat/model/chat_detail_route_args.dart';

/// Push + foreground in-app banner bridge for OneSignal.
class PushNotificationService {
  var _started = false;

  Future<void> start() async {
    if (_started) return;
    if (!OneSignalConfig.isConfigured) {
      if (kDebugMode) {
        debugPrint(
          'OneSignal App ID missing — set ONE_SIGNAL_APP_ID '
          '(--dart-define or onesignal_config.dart defaultValue).',
        );
      }
      return;
    }
    _started = true;

    OneSignal.Debug.setLogLevel(
      kDebugMode ? OSLogLevel.verbose : OSLogLevel.warn,
    );
    OneSignal.initialize(OneSignalConfig.appId);
    await OneSignal.Notifications.requestPermission(true);

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      // App open → custom banner only (no duplicate system tray). If the
      // banner can't be drawn, let the system notification through rather
      // than dropping it silently.
      final handled = _handleForeground(event.notification);
      if (handled) event.preventDefault();
    });

    OneSignal.Notifications.addClickListener((event) {
      _openFromPayload(event.notification.additionalData);
    });
  }

  Future<void> login(String userId) async {
    if (!_started || userId.trim().isEmpty) return;
    await OneSignal.login(userId.trim());
  }

  Future<void> logout() async {
    if (!_started) return;
    await OneSignal.logout();
  }

  /// Wired in app init so a pushed notification isn't repeated by the poller.
  // ignore: use_setters_to_change_properties
  void attachSeenSink(void Function(String notificationId) sink) {
    _seenSink = sink;
  }

  void Function(String notificationId)? _seenSink;

  // ignore: use_setters_to_change_properties
  void attachChatSeenSink(void Function(String key) sink) {
    _chatSeenSink = sink;
  }

  void Function(String key)? _chatSeenSink;

  /// Returns true when the OS tray should be suppressed (banner shown or
  /// intentionally swallowed for the active chat).
  bool _handleForeground(OSNotification notification) {
    final data = notification.additionalData ?? const <String, dynamic>{};
    final type = (data['type'] as String?)?.trim() ?? '';

    if (type == 'chat_message' || type == 'chat_request') {
      return _handleChatForeground(notification, data);
    }

    return _showSocialInAppFromPush(notification, data);
  }

  bool _handleChatForeground(
    OSNotification notification,
    Map<String, dynamic> data,
  ) {
    final conversationId = (data['conversationId'] as String?)?.trim() ?? '';
    final actorId = (data['actorId'] as String?)?.trim() ?? '';
    final preview = (data['preview'] as String?)?.trim().isNotEmpty == true
        ? (data['preview'] as String).trim()
        : (notification.body ?? '').trim();
    final lastMessageAt = (data['lastMessageAt'] as String?)?.trim() ?? '';

    final key = ChatNotificationWatcher.seenKey(
      conversationId: conversationId,
      messagePreview: preview,
      lastMessageAt: lastMessageAt,
    );
    _chatSeenSink?.call(key);

    if (ActiveChatTracker.instance.isViewing(
      conversationId: conversationId,
      peerUserId: actorId,
    )) {
      // Already in this thread — swallow tray, no banner.
      return true;
    }

    final username = (data['username'] as String?)?.trim() ?? '';
    final displayName = (data['displayName'] as String?)?.trim();
    final avatarUrl = (data['avatarUrl'] as String?)?.trim() ?? '';
    final isRequest =
        data['isRequest'] == true ||
        data['isRequest'] == 'true' ||
        (data['folder'] as String?)?.trim() == 'request' ||
        typeIsRequest(data);

    final name = (displayName?.isNotEmpty ?? false)
        ? displayName!
        : (username.isNotEmpty ? username : 'user');

    return AppInAppNotification.instance.show(
      InAppNotificationData(
        username: username.isNotEmpty ? username : name,
        displayName: name,
        messageKey: isRequest
            ? 'chat_message_request'
            : 'chat_message_received',
        avatarPath: avatarUrl,
        action: InAppNotificationAction.openChat,
        conversationId: conversationId,
        userId: actorId,
        isRequest: isRequest,
        subtitleKey: preview.isEmpty ? null : 'chat_push_preview',
        subtitleNamedArgs: preview.isEmpty
            ? const {}
            : {'text': preview},
      ),
    );
  }

  bool typeIsRequest(Map<String, dynamic> data) {
    final type = (data['type'] as String?)?.trim() ?? '';
    return type == 'chat_request';
  }

  bool _showSocialInAppFromPush(
    OSNotification notification,
    Map<String, dynamic> data,
  ) {
    final username = (data['username'] as String?)?.trim() ?? '';
    final displayName = (data['displayName'] as String?)?.trim();
    final avatarUrl = (data['avatarUrl'] as String?)?.trim() ?? '';
    final messageKey = (data['messageKey'] as String?)?.trim() ?? '';
    final actionRaw = (data['action'] as String?)?.trim() ?? 'none';
    final type = (data['type'] as String?)?.trim() ?? '';
    final thumbnailUrl = (data['thumbnailUrl'] as String?)?.trim() ?? '';
    final objectId = (data['objectId'] as String?)?.trim() ?? '';
    final actorId = (data['actorId'] as String?)?.trim() ?? '';

    final notificationId = (data['notificationId'] as String?)?.trim() ?? '';
    final aggForSeen =
        int.tryParse((data['aggCount'] as String?)?.trim() ?? '') ??
        (data['aggCount'] is num ? (data['aggCount'] as num).toInt() : 1);
    if (notificationId.isNotEmpty) {
      _seenSink?.call('$notificationId:${aggForSeen < 1 ? 1 : aggForSeen}');
    }

    if (messageKey.isEmpty && (notification.body ?? '').isEmpty) return false;

    final isStoryLike = type == 'story_like';
    final aggCount = aggForSeen < 1 ? 1 : aggForSeen;
    final isAgg = isStoryLike && aggCount >= 2;
    final action = switch (actionRaw) {
      'accept_follow_request' => InAppNotificationAction.friendRequest,
      'follow_back' => InAppNotificationAction.followBack,
      'open_chat' => InAppNotificationAction.openChat,
      'open_story' => InAppNotificationAction.openStory,
      _ => isStoryLike
          ? InAppNotificationAction.openStory
          : InAppNotificationAction.none,
    };

    return AppInAppNotification.instance.show(
      InAppNotificationData(
        username: isAgg
            ? ''
            : (username.isNotEmpty ? username : 'user'),
        displayName: isAgg ? null : displayName,
        messageKey: messageKey.isNotEmpty
            ? messageKey
            : (isAgg
                ? 'notifications_people_liked_story'
                : (isStoryLike
                    ? 'notifications_liked_story'
                    : 'notifications_started_following')),
        messageNamedArgs: isAgg ? {'count': '$aggCount'} : const {},
        avatarPath: avatarUrl,
        action: action,
        leadingIconPath:
            isStoryLike ? AssetPaths.iconHeartCircleFilled : null,
        storyImagePath: thumbnailUrl.isNotEmpty ? thumbnailUrl : null,
        storyId: objectId,
        userId: actorId,
        useFullTitle: isAgg || (messageKey.isEmpty && !isStoryLike),
      ),
    );
  }

  void _openFromPayload(Map<String, dynamic>? raw) {
    if (raw == null) return;
    final type = (raw['type'] as String?)?.trim() ?? '';
    final context = AppRouter.rootKey.currentContext;
    if (context == null) return;

    if (type == 'story_like' ||
        (raw['action'] as String?)?.trim() == 'open_story') {
      final objectId = (raw['objectId'] as String?)?.trim() ?? '';
      if (objectId.isEmpty) return;
      unawaited(openStoryById(context, storyId: objectId));
      return;
    }

    if (type != 'chat_message' && type != 'chat_request') return;

    final conversationId = (raw['conversationId'] as String?)?.trim() ?? '';
    final actorId = (raw['actorId'] as String?)?.trim() ?? '';
    final username = (raw['username'] as String?)?.trim() ?? '';
    final displayName = (raw['displayName'] as String?)?.trim();
    final avatarUrl = (raw['avatarUrl'] as String?)?.trim() ?? '';
    final isRequest =
        raw['isRequest'] == true ||
        raw['isRequest'] == 'true' ||
        (raw['folder'] as String?)?.trim() == 'request' ||
        type == 'chat_request';
    final name = (displayName?.isNotEmpty ?? false)
        ? displayName!
        : (username.isNotEmpty ? username : 'user');

    context.push(
      RoutePaths.chatDetail.path,
      extra: ChatDetailRouteArgs(
        name: name,
        username: username.isNotEmpty ? username : name,
        avatarPath: avatarUrl,
        userId: actorId,
        conversationId: conversationId,
        isRequest: isRequest,
      ),
    );
  }
}
