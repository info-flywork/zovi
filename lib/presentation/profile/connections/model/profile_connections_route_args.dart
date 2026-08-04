import 'package:flutter/foundation.dart';
enum ProfileConnectionsTab { followers, friends }

@immutable
final class ProfileConnectionsRouteArgs {
  const ProfileConnectionsRouteArgs({
    required this.name,
    required this.followersCount,
    required this.friendsCount,
    this.userId = '',
    this.isOwnProfile = false,
    this.initialTab = ProfileConnectionsTab.followers,
  });

  final String name;
  final String userId;
  final int followersCount;
  final int friendsCount;
  final bool isOwnProfile;
  final ProfileConnectionsTab initialTab;
}
