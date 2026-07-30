class StoryDraftItem {
  const StoryDraftItem({
    required this.id,
    required this.mediaUrl,
    this.createdAt,
  });

  factory StoryDraftItem.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    final raw = json['createdAt'];
    if (raw is String && raw.trim().isNotEmpty) {
      createdAt = DateTime.tryParse(raw)?.toLocal();
    }
    return StoryDraftItem(
      id: (json['id'] as String?)?.trim() ?? '',
      mediaUrl: (json['mediaUrl'] as String?)?.trim() ?? '',
      createdAt: createdAt,
    );
  }

  final String id;
  final String mediaUrl;
  final DateTime? createdAt;
}
