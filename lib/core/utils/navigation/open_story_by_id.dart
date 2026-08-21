import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/stories/model/story_detail_route_args.dart';

/// Opens the existing [StoryDetailView] with the owner's live story ring
/// (same path as feed / profile avatar tap) — never a one-off mock item.
Future<void> openStoryById(
  BuildContext context, {
  required String storyId,
  String? ownerUserId,
}) async {
  final id = storyId.trim();
  if (id.isEmpty) return;

  final repo = getIt<UserRepository>();
  final myId = getIt<AuthRepository>().backendUserId?.trim() ?? '';
  final owner = (ownerUserId ?? '').trim().isNotEmpty
      ? ownerUserId!.trim()
      : myId;
  if (owner.isEmpty) return;

  final items = await repo.getStoryItemsForUser(owner);
  if (!context.mounted || items.isEmpty) return;

  final hydrated = repo.hydrateStoryLikeState(items);
  var index = hydrated.indexWhere((e) => (e.storyId ?? '').trim() == id);
  if (index < 0) index = 0;

  await context.push(
    RoutePaths.storyDetail.path,
    extra: StoryDetailRouteArgs(items: hydrated, initialIndex: index),
  );
}
