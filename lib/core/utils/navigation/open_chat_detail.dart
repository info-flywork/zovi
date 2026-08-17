import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/domain/tribe/tribe_repository.dart';
import 'package:zovi/presentation/chat/model/chat_detail_route_args.dart';

/// Builds chat route args. Group notifications carry the *sender* as actor —
/// title/avatar must come from the tribe, not that person.
ChatDetailRouteArgs chatDetailArgsFromNotification({
  required String conversationId,
  required bool isGroup,
  String tribeId = '',
  String groupName = '',
  String actorName = '',
  String actorUsername = '',
  String actorAvatar = '',
  String actorUserId = '',
  bool isRequest = false,
}) {
  final cid = conversationId.trim();
  final tid = tribeId.trim();
  final actor = actorName.trim().isNotEmpty
      ? actorName.trim()
      : actorUsername.trim();
  final handle = actorUsername.trim().isNotEmpty ? actorUsername.trim() : actor;
  final avatar = actorAvatar.trim();

  if (!isGroup && tid.isEmpty) {
    return ChatDetailRouteArgs(
      name: actor.isNotEmpty ? actor : 'user',
      username: handle.isNotEmpty ? handle : (actor.isNotEmpty ? actor : 'user'),
      avatarPath: avatar.isNotEmpty ? avatar : AssetPaths.avatarYou,
      userId: actorUserId.trim(),
      conversationId: cid,
      isRequest: isRequest,
    );
  }

  final tribe = getIt<TribeRepository>().findCachedTribe(
    tribeId: tid,
    conversationId: cid,
  );
  final tribeName = tribe?.name.trim() ?? '';
  final payloadName = groupName.trim();
  final name = tribeName.isNotEmpty
      ? tribeName
      : (payloadName.isNotEmpty ? payloadName : actor);
  final groupAvatar = (tribe != null && tribe.avatars.isNotEmpty)
      ? tribe.avatars.first.trim()
      : '';

  return ChatDetailRouteArgs(
    name: name.isNotEmpty ? name : 'tribe',
    username: name.isNotEmpty ? name : 'tribe',
    avatarPath: groupAvatar.isNotEmpty
        ? groupAvatar
        : (avatar.isNotEmpty ? avatar : AssetPaths.avatarYou),
    conversationId: cid,
    isGroup: true,
    memberCount: (tribe != null && tribe.memberCount > 0)
        ? tribe.memberCount
        : null,
    tribeId: (tribe?.id.trim().isNotEmpty ?? false) ? tribe!.id.trim() : tid,
  );
}
