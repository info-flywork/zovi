import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:zovi/core/chat/active_chat_tracker.dart';
import 'package:zovi/core/in_app_notification/app_in_app_notification.dart';
import 'package:zovi/core/in_app_notification/in_app_notification_data.dart';
import 'package:zovi/core/notifications/chat_notification_watcher.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/domain/auth/auth_repository.dart';

/// Shows the in-app banner for notifications that arrive while the app is
/// open, without depending on a push actually reaching the device.
///
/// APNs drops pushes for a debug build whenever the OneSignal app is pinned to
/// the production environment, and the OS can throttle them at any time.
/// Polling the inbox keeps the banner working in both cases; ids seen here and
/// ids claimed by an incoming push share one set, so nothing shows twice.
final class NotificationInboxWatcher with WidgetsBindingObserver {
  NotificationInboxWatcher(this._authRepository);

  static const _interval = Duration(seconds: 10);

  /// Until the inbox is primed there is nothing to fetch yet (sign-in is still
  /// in flight), so ticking fast here costs nothing and closes the window where
  /// a notification arriving right after launch would be swallowed by priming.
  static const _warmupInterval = Duration(seconds: 2);

  /// Keeps memory bounded on long sessions; far above one poll page.
  static const _seenLimit = 300;

  static const _pageSize = 30;

  final AuthRepository _authRepository;

  /// Latest inbox page. Screens listen to this instead of re-fetching, so a
  /// CTA that the server recomputed (accepted request, follow back) settles
  /// without the user leaving and re-entering the page.
  final inbox = ValueNotifier<List<AppNotificationItem>>(const []);

  Timer? _timer;
  final _seen = <String>{};
  String? _primedUserId;
  var _polling = false;
  var _foreground = true;

  void start() {
    if (_timer != null) return;
    WidgetsBinding.instance.addObserver(this);
    _schedule(_warmupInterval);
    unawaited(_poll());
  }

  void stop() {
    if (_timer == null) return;
    _timer!.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
    _seen.clear();
    _primedUserId = null;
  }

  /// Pulls the inbox right away — used after an action so the row settles to
  /// the server's recomputed CTA instead of waiting for the next tick.
  Future<void> refresh() => _poll();

  /// Lets the push handler claim an id so the next poll stays quiet.
  void markSeen(String notificationId) {
    final id = notificationId.trim();
    if (id.isNotEmpty) _remember(id);
  }

  /// Lets the chat watcher claim a banner key so inbox + chat poll never double-fire.
  // ignore: use_setters_to_change_properties
  void attachChatSeenSink(void Function(String key) sink) {
    _chatSeenSink = sink;
  }

  void Function(String key)? _chatSeenSink;

  /// Conversation banner keys the chat watcher already surfaced.
  final _chatBannerKeys = <String>{};

  void markChatBannerSeen(String key) {
    final k = key.trim();
    if (k.isEmpty) return;
    _chatBannerKeys.add(k);
    if (_chatBannerKeys.length > _seenLimit) {
      _chatBannerKeys.remove(_chatBannerKeys.first);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // `inactive`/`hidden` are transient (control centre, app switcher preview)
    // and must not stop polling — only a real background does.
    _foreground = state != AppLifecycleState.paused &&
        state != AppLifecycleState.detached;
    if (state == AppLifecycleState.resumed) unawaited(_poll());
  }

  void _schedule(Duration interval) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => unawaited(_poll()));
  }

  Future<void> _poll() async {
    if (_polling || _timer == null || !_foreground) return;
    final userId = _authRepository.backendUserId?.trim() ?? '';
    if (userId.isEmpty) return;

    _polling = true;
    try {
      final items = await _authRepository.fetchNotifications(limit: _pageSize);
      inbox.value = items;
      final priming = _primedUserId != userId;
      if (priming) {
        _seen.clear();
        _primedUserId = userId;
        _schedule(_interval);
      }
      _log('poll user=$userId items=${items.length} priming=$priming');

      // Oldest first so a burst shows in arrival order.
      for (final item in items.reversed) {
        if (item.id.isEmpty) continue;
        final seenKey = _seenKey(item);
        if (_seen.contains(seenKey)) continue;

        // Priming records the existing inbox without replaying it as banners;
        // anything already read is likewise only recorded.
        if (priming || item.readAt != null) {
          _remember(seenKey);
          continue;
        }
        // A failed show (no overlay mounted yet) stays unremembered so the
        // next tick retries instead of losing the banner.
        if (_show(item)) _remember(seenKey);
      }
    } catch (error) {
      // Offline or expired token — the next tick retries.
      _log('poll failed: $error');
    } finally {
      _polling = false;
    }
  }

  String _seenKey(AppNotificationItem item) {
    final count = item.aggCount ?? 1;
    return '${item.id}:$count';
  }

  void _remember(String key) {
    _seen.add(key);
    if (_seen.length > _seenLimit) _seen.remove(_seen.first);
  }

  /// Returns false only when the banner should be retried later.
  bool _show(AppNotificationItem item) {
    final isChat =
        item.type == 'chat_message' || item.type == 'chat_request';
    if (isChat) {
      return _showChat(item);
    }

    final isStoryLike = item.type == 'story_like';
    final aggCount = item.aggCount ?? 1;
    final isAgg = isStoryLike && aggCount >= 2;
    final messageKey = switch (item.type) {
      'follow_request' => 'notifications_follow_request',
      'started_following' => 'notifications_started_following',
      'follow_accepted' => 'notifications_follow_accepted',
      'check_in_tagged' => 'notifications_check_in_tagged',
      'story_like' => isAgg
          ? 'notifications_people_liked_story'
          : 'notifications_liked_story',
      _ => item.bodyKey ?? '',
    };
    if (messageKey.isEmpty) return true;

    final username = item.actorUsername?.trim() ?? '';
    final thumbnail = item.thumbnailUrl?.trim() ?? '';

    final shown = AppInAppNotification.instance.show(
      InAppNotificationData(
        username: isAgg
            ? ''
            : (username.isNotEmpty ? username : 'user'),
        displayName: isAgg ? null : item.actorName,
        messageKey: messageKey,
        messageNamedArgs: isAgg ? {'count': '$aggCount'} : const {},
        avatarPath: item.actorAvatarUrl ?? '',
        action: switch (item.action) {
          'accept_follow_request' => InAppNotificationAction.friendRequest,
          'follow_back' => InAppNotificationAction.followBack,
          'open_story' => InAppNotificationAction.openStory,
          _ => isStoryLike
              ? InAppNotificationAction.openStory
              : InAppNotificationAction.none,
        },
        leadingIconPath:
            isStoryLike ? AssetPaths.iconHeartCircleFilled : null,
        storyImagePath: thumbnail.isNotEmpty ? thumbnail : null,
        storyId: item.objectId?.trim() ?? '',
        userId: item.actorId?.trim() ?? '',
        useFullTitle: isAgg,
      ),
    );
    _log('banner ${item.type} id=${item.id} shown=$shown');
    return shown;
  }

  bool _showChat(AppNotificationItem item) {
    final payload = item.payload ?? const {};
    final conversationId =
        (payload['conversationId'] as String?)?.trim().isNotEmpty == true
        ? (payload['conversationId'] as String).trim()
        : (item.objectId?.trim() ?? '');
    final lastMessageAt = (payload['lastMessageAt'] as String?)?.trim() ?? '';
    final preview = (payload['preview'] as String?)?.trim() ?? '';
    final chatKey = ChatNotificationWatcher.seenKey(
      conversationId: conversationId,
      lastMessageAt: lastMessageAt,
      messagePreview: preview,
    );
    if (_chatBannerKeys.contains(chatKey)) return true;

    // Already inside this thread — swallow, no banner.
    if (ActiveChatTracker.instance.isViewing(
      conversationId: conversationId,
      peerUserId: item.actorId,
    )) {
      return true;
    }

    final aggCount = item.aggCount ?? 1;
    final isAgg = aggCount >= 2;
    final isRequest =
        item.type == 'chat_request' ||
        payload['isRequest'] == true ||
        payload['isRequest'] == 'true';
    final tribeId = (payload['tribeId'] as String?)?.trim() ?? '';
    final groupName =
        (payload['groupName'] as String?)?.trim().isNotEmpty == true
        ? (payload['groupName'] as String).trim()
        : ((payload['tribeName'] as String?)?.trim() ?? '');
    final isGroup =
        payload['isGroup'] == true ||
        payload['isGroup'] == 'true' ||
        tribeId.isNotEmpty;
    final username = item.actorUsername?.trim() ?? '';
    final actorName = item.actorName?.trim() ?? '';
    final messageKey = isAgg
        ? 'notifications_chat_messages_batch'
        : (isRequest ? 'chat_message_request' : 'chat_message_received');

    final shown = AppInAppNotification.instance.show(
      InAppNotificationData(
        username: isAgg
            ? ''
            : (username.isNotEmpty
                ? username
                : (actorName.isNotEmpty ? actorName : 'user')),
        displayName: isAgg && isGroup && groupName.isNotEmpty
            ? groupName
            : (actorName.isNotEmpty ? actorName : null),
        messageKey: messageKey,
        messageNamedArgs: isAgg ? {'count': '$aggCount'} : const {},
        avatarPath: item.actorAvatarUrl ?? '',
        action: InAppNotificationAction.openChat,
        conversationId: conversationId,
        userId: item.actorId?.trim() ?? '',
        isRequest: isRequest,
        isGroup: isGroup,
        tribeId: tribeId,
        groupName: groupName,
        useFullTitle: isAgg,
        subtitleKey: !isAgg && preview.isNotEmpty ? 'chat_push_preview' : null,
        subtitleNamedArgs:
            !isAgg && preview.isNotEmpty ? {'text': preview} : const {},
        storyImagePath: item.thumbnailUrl?.trim().isNotEmpty == true
            ? item.thumbnailUrl
            : null,
      ),
    );
    if (shown) {
      _chatSeenSink?.call(chatKey);
      markChatBannerSeen(chatKey);
    }
    _log('banner chat id=${item.id} shown=$shown');
    return shown;
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('inbox_watcher: $message');
  }
}
