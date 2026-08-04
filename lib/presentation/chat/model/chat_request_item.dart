class ChatRequestItem {
  const ChatRequestItem({
    required this.conversationId,
    required this.userId,
    required this.name,
    required this.username,
    required this.avatarPath,
    required this.preview,
    this.isUnread = true,
  });

  final String conversationId;
  final String userId;
  final String name;
  final String username;
  final String avatarPath;
  final String preview;
  final bool isUnread;

  ChatRequestItem copyWith({bool? isUnread}) {
    return ChatRequestItem(
      conversationId: conversationId,
      userId: userId,
      name: name,
      username: username,
      avatarPath: avatarPath,
      preview: preview,
      isUnread: isUnread ?? this.isUnread,
    );
  }
}

class ChatRequestsRouteArgs {
  const ChatRequestsRouteArgs({required this.requests});

  final List<ChatRequestItem> requests;
}
