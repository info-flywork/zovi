import 'package:flutter/foundation.dart';
import 'package:zovi/core/utils/media_kind.dart';

@immutable
final class StoryDraftItem {
  const StoryDraftItem({
    required this.id,
    required this.mediaUrl,
    this.mediaType = 'image',
    this.createdAt,
  });

  factory StoryDraftItem.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    final raw = json['createdAt'];
    if (raw is String && raw.trim().isNotEmpty) {
      createdAt = DateTime.tryParse(raw)?.toLocal();
    }
    final mediaUrl = (json['mediaUrl'] as String?)?.trim() ?? '';
    final mediaType = (json['mediaType'] as String?)?.trim() ?? '';
    return StoryDraftItem(
      id: (json['id'] as String?)?.trim() ?? '',
      mediaUrl: mediaUrl,
      mediaType: mediaType.isEmpty
          ? (isVideoMediaPath(mediaUrl) ? 'video' : 'image')
          : mediaType,
      createdAt: createdAt,
    );
  }

  final String id;
  final String mediaUrl;
  final String mediaType;
  final DateTime? createdAt;

  bool get isVideo => isVideoMedia(mediaType: mediaType, path: mediaUrl);
}
