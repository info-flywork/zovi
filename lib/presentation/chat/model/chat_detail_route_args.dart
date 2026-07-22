class ChatDetailRouteArgs {
  const ChatDetailRouteArgs({
    required this.name,
    required this.username,
    required this.avatarPath,
    this.lastActive = '4h',
    this.isGroup = false,
    this.memberCount,
  });

  final String name;
  final String username;
  final String avatarPath;
  final String lastActive;
  final bool isGroup;
  final int? memberCount;

  String get headerTitle => isGroup ? name : username;
}
