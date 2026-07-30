import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/profile/user_profile/model/user_profile_route_args.dart';

/// Pushes the public profile immediately (no await on network).
/// [seed] fills avatar/name from story/chat so the first frame isn't empty.
Future<void> openUserProfile(
  BuildContext context,
  String usernameOrName, {
  PublicUserProfile? seed,
}) async {
  final value = usernameOrName.trim();
  if (value.isEmpty) return;
  if (value.toLowerCase() == 'you') return;

  final handle = value.startsWith('@') ? value.substring(1) : value;
  final repo = getIt<UserRepository>();
  final peeked = repo.peekPublicUserProfile(handle);
  final initial = peeked ??
      seed ??
      PublicUserProfile.skeleton(username: handle);

  if (!context.mounted) return;
  context.push(
    RoutePaths.userProfile.path,
    extra: UserProfileRouteArgs(user: initial),
  );
}
