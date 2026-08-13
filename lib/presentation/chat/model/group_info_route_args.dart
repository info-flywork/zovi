import 'package:flutter/foundation.dart';
@immutable
final class GroupInfoRouteArgs {
  const GroupInfoRouteArgs({
    required this.name,
    required this.avatarPath,
    required this.memberCount,
    this.streakCount = 12,
    this.tribeId = '',
    this.conversationId = '',
  });

  final String name;
  final String avatarPath;
  final int memberCount;
  final int streakCount;
  final String tribeId;
  final String conversationId;
}
