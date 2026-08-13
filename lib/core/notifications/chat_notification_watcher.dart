import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:zovi/core/chat/active_chat_tracker.dart';
import 'package:zovi/core/in_app_notification/app_in_app_notification.dart';
import 'package:zovi/core/in_app_notification/in_app_notification_data.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/domain/chat/chat_repository.dart';

/// Foreground chat banners when OneSignal/APNs doesn't deliver (common in
/// debug). Shares a seen-key set with [PushNotificationService] so a push
/// and a poll never double-fire the same message.
class ChatNotificationWatcher with WidgetsBindingObserver {
  ChatNotificationWatcher(this._chat, this._auth);

  static const _interval = Duration(seconds: 2);
  static const _warmupInterval = Duration(milliseconds: 800);
  static const _seenLimit = 200;

  final ChatRepository _chat;
  final AuthRepository _auth;

  Timer? _timer;
  final _seen = <String>{};
  /// conversationId → last known lastMessageAt iso / unread fingerprint
  final _fingerprints = <String, String>{};
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
    _fingerprints.clear();
    _primedUserId = null;
  }

  /// Called when a chat push already showed (or was swallowed for active chat).
  void markSeen(String key) {
    final k = key.trim();
    if (k.isEmpty) return;
    _remember(k);
  }

  void Function(String key)? _inboxBannerSink;

  /// Lets the inbox watcher skip a chat banner the conversation poll already showed.
  // ignore: use_setters_to_change_properties
  void attachInboxBannerSink(void Function(String key) sink) {
    _inboxBannerSink = sink;
  }

  static String seenKey({
    required String conversationId,
    String? messagePreview,
    String? lastMessageAt,
  }) {
    final c = conversationId.trim();
    final at = (lastMessageAt ?? '').trim();
    final preview = (messagePreview ?? '').trim();
    if (at.isNotEmpty) return '$c|$at';
    return '$c|$preview';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
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
    final myId = _auth.backendUserId?.trim() ?? '';
    if (myId.isEmpty) return;

    _polling = true;
    try {
      final results = await Future.wait([
        _chat.listConversations(folder: 'inbox'),
        _chat.listConversations(folder: 'request'),
      ]);
      final priming = _primedUserId != myId;
      if (priming) {
        _seen.clear();
        _fingerprints.clear();
        _primedUserId = myId;
        _schedule(_interval);
      }

      final all = [...results[0], ...results[1]];
      for (final c in all) {
        if (c.id.isEmpty) continue;
        final at = c.lastMessageAt?.toUtc().toIso8601String() ?? '';
        final fingerprint = '$at|${c.unreadCount}|${c.lastMessagePreview}';
        final prev = _fingerprints[c.id];
        _fingerprints[c.id] = fingerprint;

        if (priming) {
          if (at.isNotEmpty) {
            _remember(seenKey(conversationId: c.id, lastMessageAt: at));
          }
          continue;
        }
        if (prev == fingerprint) continue;
        if (c.unreadCount <= 0) continue;

        // Only banner when the peer sent the latest message.
        final sender = (c.lastMessageSenderId ?? '').trim();
        if (sender.isNotEmpty && sender == myId) continue;

        if (ActiveChatTracker.instance.isViewing(
          conversationId: c.id,
          peerUserId: c.peer.userId,
        )) {
          _remember(seenKey(conversationId: c.id, lastMessageAt: at));
          continue;
        }

        final key = seenKey(
          conversationId: c.id,
          lastMessageAt: at,
          messagePreview: c.lastMessagePreview,
        );
        if (_seen.contains(key)) continue;

        final name = c.peer.name.trim().isNotEmpty
            ? c.peer.name.trim()
            : (c.peer.username.trim().isNotEmpty ? c.peer.username : 'user');
        final shown = AppInAppNotification.instance.show(
          InAppNotificationData(
            username: c.peer.username.trim().isNotEmpty
                ? c.peer.username.trim()
                : name,
            displayName: name,
            messageKey: c.isRequest
                ? 'chat_message_request'
                : 'chat_message_received',
            avatarPath: c.peer.avatarUrl,
            action: InAppNotificationAction.openChat,
            conversationId: c.id,
            userId: c.peer.isGroup ? '' : c.peer.userId,
            isRequest: c.isRequest,
            isGroup: c.peer.isGroup,
            tribeId: c.peer.tribeId,
            groupName: c.peer.isGroup ? name : '',
            subtitleKey: c.lastMessagePreview.trim().isEmpty
                ? null
                : 'chat_push_preview',
            subtitleNamedArgs: c.lastMessagePreview.trim().isEmpty
                ? const {}
                : {'text': c.lastMessagePreview.trim()},
          ),
        );
        if (shown) {
          _remember(key);
          _inboxBannerSink?.call(key);
        }
      }
    } catch (error) {
      if (kDebugMode) debugPrint('chat_watcher: poll failed: $error');
    } finally {
      _polling = false;
    }
  }

  void _remember(String id) {
    _seen.add(id);
    if (_seen.length > _seenLimit) _seen.remove(_seen.first);
  }
}
