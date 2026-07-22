class GroupInfoRouteArgs {
  const GroupInfoRouteArgs({
    required this.name,
    required this.avatarPath,
    required this.memberCount,
    this.streakCount = 12,
  });

  final String name;
  final String avatarPath;
  final int memberCount;
  final int streakCount;
}
