import 'package:flutter/foundation.dart';
@immutable
final class ChatDetailRouteArgs {
  const ChatDetailRouteArgs({
    required this.name,
    required this.username,
    required this.avatarPath,
    this.userId = '',
    this.conversationId = '',
    this.lastActive = '',
    this.isGroup = false,
    this.isRequest = false,
    this.memberCount,
  });

  final String name;
  final String username;
  final String avatarPath;
  final String userId;
  final String conversationId;
  final String lastActive;
  final bool isGroup;
  /// True when opened from the message-requests folder.
  final bool isRequest;
  final int? memberCount;

  String get headerTitle => isGroup ? name : username;
}
