import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/profile/user_profile/model/user_profile_route_args.dart';

/// Pushes the public profile immediately (no await on network).
/// [seed] fills avatar/name from story/chat so the first frame isn't empty.
/// Pass [userId] when the username is hidden (e.g. anonymous map pins).
/// Completes when the profile route is popped, so callers (e.g. the story
/// viewer) can keep their media paused for as long as the profile is on top.
Future<void> openUserProfile(
  BuildContext context,
  String usernameOrName, {
  PublicUserProfile? seed,
  String? userId,
}) async {
  final value = usernameOrName.trim();
  final resolvedUserId = userId?.trim() ?? seed?.userId.trim() ?? '';
  if (value.isEmpty && resolvedUserId.isEmpty) return;
  if (value.toLowerCase() == 'you') return;

  final handle = value.startsWith('@') ? value.substring(1) : value;
  final repo = getIt<UserRepository>();
  final myHandle = repo.cachedCurrentUser?.usernameHandle.trim().toLowerCase() ?? '';
  if (handle.isNotEmpty &&
      myHandle.isNotEmpty &&
      myHandle == handle.toLowerCase()) {
    return;
  }
  final myId = getIt<AuthRepository>().backendUserId?.trim() ?? '';
  final seedId = seed?.userId.trim() ?? resolvedUserId;
  if (myId.isNotEmpty && seedId.isNotEmpty && myId == seedId) return;

  // Prefer by-id when available — long mock usernames truncate on lookup.
  final lookupById = resolvedUserId.isNotEmpty;

  final peeked = lookupById
      ? repo.peekPublicUserProfileByUserId(resolvedUserId)
      : (handle.isNotEmpty ? repo.peekPublicUserProfile(handle) : null);
  final initial = peeked ??
      seed ??
      (lookupById
          ? PublicUserProfile.skeleton(
              username: 'user',
              name: value.isNotEmpty ? value : 'Anonim',
              userId: resolvedUserId,
            )
          : PublicUserProfile.skeleton(username: handle));

  if (!context.mounted) return;
  await context.push(
    RoutePaths.userProfile.path,
    extra: UserProfileRouteArgs(user: initial),
  );
}
