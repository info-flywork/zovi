enum ProfileConnectionsTab { followers, friends }

class ProfileConnectionsRouteArgs {
  const ProfileConnectionsRouteArgs({
    required this.username,
    required this.followersCount,
    required this.friendsCount,
    this.initialTab = ProfileConnectionsTab.followers,
  });

  final String username;
  final int followersCount;
  final int friendsCount;
  final ProfileConnectionsTab initialTab;
}
