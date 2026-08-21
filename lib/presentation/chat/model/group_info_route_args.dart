import 'package:easy_localization/easy_localization.dart';
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
    this.nameKey = '',
  });

  final String name;
  final String avatarPath;
  final int memberCount;
  final int streakCount;
  final String tribeId;
  final String conversationId;
  final String nameKey;

  String get localizedName {
    final key = nameKey.trim();
    if (key.isNotEmpty) {
      final translated = key.tr();
      if (translated != key) return translated;
    }
    return name;
  }
}
