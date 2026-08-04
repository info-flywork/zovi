import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/notifications/notification_inbox_watcher.dart';
import 'package:zovi/core/snackbar/app_snackbar.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/utils/navigation/open_story_by_id.dart';
import 'package:zovi/core/utils/navigation/open_user_profile.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/app_loading.dart';
import 'package:zovi/core/widgets/profile_avatar.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/chat/model/chat_detail_route_args.dart';
import 'package:zovi/presentation/chat/view/widgets/chat_swipe_delete_tile.dart';

enum _NotificationAction { followBack, sendMessage, acceptRequest, requestSent }

enum _NotificationLeading { avatar, heartCircle }

enum _ActionState { idle, followRequestSent, requestSent }

class _NotificationItem {
  const _NotificationItem({
    required this.id,
    required this.type,
    required this.username,
    required this.messageKey,
    required this.leading,
    this.createdAt,
    this.avatarPath,
    this.action,
    this.thumbnailPath,
    this.showLikeBadge = false,
    this.count,
    this.displayName,
    this.objectId,
    this.actorUserId,
  });

  final String id;
  final String type;
  final String username;
  final String messageKey;
  final DateTime? createdAt;
  final _NotificationLeading leading;
  final String? avatarPath;
  final _NotificationAction? action;
  final String? thumbnailPath;
  final bool showLikeBadge;
  final int? count;
  final String? displayName;
  final String? objectId;
  final String? actorUserId;

  bool get isStoryLike =>
      showLikeBadge ||
      leading == _NotificationLeading.heartCircle ||
      type == 'story_like' ||
      messageKey == 'notifications_liked_story' ||
      messageKey == 'notifications_people_liked_story';

  _NotificationItem copyWith({
    String? messageKey,
    _NotificationAction? action,
    bool clearAction = false,
  }) {
    return _NotificationItem(
      id: id,
      type: type,
      username: username,
      messageKey: messageKey ?? this.messageKey,
      createdAt: createdAt,
      leading: leading,
      avatarPath: avatarPath,
      action: clearAction ? null : (action ?? this.action),
      thumbnailPath: thumbnailPath,
      showLikeBadge: showLikeBadge,
      count: count,
      displayName: displayName,
      objectId: objectId,
      actorUserId: actorUserId,
    );
  }
}

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  var _loading = true;
  List<_NotificationItem> _items = const [];
  final Map<String, _ActionState> _actionStates = {};
  final Set<String> _busy = {};

  /// Rows collapsing out of the list; kept until their animation finishes.
  final Set<String> _removing = {};

  /// Ids the server has confirmed deleted — a poll in flight must not re-add
  /// them if it was issued before the delete landed.
  final Set<String> _deleted = {};
  final _watcher = getIt<NotificationInboxWatcher>();
  Timer? _clock;
  String? _openedSwipeId;

  @override
  void initState() {
    super.initState();
    _watcher.inbox.addListener(_onInboxChanged);
    // Relative labels ("3dk") need a tick so they age while the page is open.
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    unawaited(_load());
  }

  @override
  void dispose() {
    _clock?.cancel();
    _watcher.inbox.removeListener(_onInboxChanged);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final remote = await getIt<AuthRepository>().fetchNotifications();
      if (!mounted) return;
      setState(() {
        _items = [for (final n in remote) _mapRemote(n)];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _loading = false;
      });
    }
  }

  void _onInboxChanged() {
    if (mounted) _applyRemote(_watcher.inbox.value);
  }

  /// The poller only carries the newest page. Remap that page onto the list,
  /// keep optimistic paint for rows with a request in flight, and drop anything
  /// the server no longer returns (deleted / read-cleared).
  void _applyRemote(List<AppNotificationItem> remote) {
    setState(() {
      final current = {for (final item in _items) item.id: item};
      final next = <_NotificationItem>[];
      for (final n in remote) {
        if (_deleted.contains(n.id)) continue;
        final existing = current[n.id];
        next.add(
          _busy.contains(n.id) && existing != null ? existing : _mapRemote(n),
        );
      }
      // A row mid-collapse stays at its slot until the animation completes,
      // otherwise it would vanish instantly once the server stops sending it.
      for (var i = 0; i < _items.length; i++) {
        final item = _items[i];
        if (_removing.contains(item.id) &&
            !next.any((e) => e.id == item.id)) {
          next.insert(i.clamp(0, next.length), item);
        }
      }
      _items = next;
      for (final n in remote) {
        if (!_busy.contains(n.id)) _actionStates.remove(n.id);
      }
      _loading = false;
    });
  }

  _NotificationItem _mapRemote(AppNotificationItem n) {
    final action = switch (n.action) {
      'accept_follow_request' => _NotificationAction.acceptRequest,
      'follow_back' => _NotificationAction.followBack,
      'request_sent' => _NotificationAction.requestSent,
      'send_message' => _NotificationAction.sendMessage,
      _ => null,
    };
    final messageKey = switch (n.type) {
      'follow_request' => 'notifications_follow_request',
      'started_following' => 'notifications_started_following',
      'follow_accepted' => 'notifications_follow_accepted',
      'story_like' => (n.aggCount ?? 0) >= 2
          ? 'notifications_people_liked_story'
          : 'notifications_liked_story',
      'check_in_tagged' => 'notifications_check_in_tagged',
      _ => n.bodyKey ?? 'notifications_started_following',
    };
    final isStoryLike =
        n.type == 'story_like' ||
        messageKey == 'notifications_liked_story' ||
        messageKey == 'notifications_people_liked_story';
    final isAggStoryLike = isStoryLike && (n.aggCount ?? 0) >= 2;
    return _NotificationItem(
      id: n.id,
      type: n.type,
      username: isAggStoryLike ? '' : (n.actorUsername ?? ''),
      displayName: isAggStoryLike ? null : n.actorName,
      messageKey: messageKey,
      createdAt: n.createdAt,
      // Single like → actor avatar + heart badge; multi → red heart circle.
      leading: isAggStoryLike
          ? _NotificationLeading.heartCircle
          : _NotificationLeading.avatar,
      avatarPath: n.actorAvatarUrl,
      thumbnailPath: n.thumbnailUrl,
      showLikeBadge: isStoryLike && !isAggStoryLike,
      count: isAggStoryLike ? n.aggCount : null,
      action: action,
      objectId: n.objectId,
      actorUserId: n.actorId,
    );
  }

  static String formatRelativeTime(DateTime? at) {
    if (at == null) return '';
    final now = DateTime.now();
    var when = at.toLocal();
    var elapsed = now.difference(when);

    // Session-TZ DATETIME read as UTC arrives skewed into the future and
    // otherwise sticks on "şimdi" forever (negative elapsed still < 60s).
    if (elapsed.isNegative) {
      if (elapsed.inMinutes > -5) {
        elapsed = Duration.zero;
      } else {
        when = when.subtract(now.timeZoneOffset);
        elapsed = now.difference(when);
        if (elapsed.isNegative) elapsed = Duration.zero;
      }
    }

    final seconds = elapsed.inSeconds;
    if (seconds < 60) return 'time_just_now'.tr();
    if (seconds < 3600) {
      return 'time_minutes'.tr(
        namedArgs: {'count': '${(seconds ~/ 60).clamp(1, 59)}'},
      );
    }
    if (seconds < 86400) {
      return 'time_hours'.tr(namedArgs: {'count': '${seconds ~/ 3600}'});
    }
    final days = seconds ~/ 86400;
    if (days < 7) {
      return 'time_days'.tr(namedArgs: {'count': '$days'});
    }
    if (days < 30) {
      return 'time_weeks'.tr(namedArgs: {'count': '${days ~/ 7}'});
    }
    return '${when.day}.${when.month}.${when.year}';
  }

  _ActionState _stateFor(String id) => _actionStates[id] ?? _ActionState.idle;

  void _replaceItem(
    String id,
    _NotificationItem Function(_NotificationItem) f,
  ) {
    setState(() {
      _items = [
        for (final existing in _items)
          if (existing.id == id) f(existing) else existing,
      ];
    });
  }

  /// Optimistic: repaint the row first, then send the request and roll back
  /// only if it fails.
  Future<void> _onAction(_NotificationItem item) async {
    final action = item.action;
    if (action == null) return;
    final auth = getIt<AuthRepository>();

    switch (action) {
      case _NotificationAction.acceptRequest:
        final requestId = item.objectId?.trim() ?? '';
        if (requestId.isEmpty || _busy.contains(item.id)) return;
        _busy.add(item.id);
        // Accept = they follow you now → offer follow-back immediately.
        _replaceItem(
          item.id,
          (e) => e.copyWith(
            messageKey: 'notifications_started_following',
            action: _NotificationAction.followBack,
          ),
        );
        setState(() => _actionStates.remove(item.id));
        try {
          final result = await auth.acceptFollowRequest(requestId);
          if (!mounted) return;
          final rel = result.relationship;
          if (rel.following) {
            _replaceItem(
              item.id,
              (e) => e.copyWith(
                messageKey: 'notifications_started_following',
                clearAction: true,
              ),
            );
          } else if (rel.outgoingRequest) {
            setState(() {
              _actionStates[item.id] = _ActionState.requestSent;
            });
            _replaceItem(
              item.id,
              (e) => e.copyWith(
                messageKey: 'notifications_started_following',
                action: _NotificationAction.requestSent,
              ),
            );
          } else {
            _replaceItem(
              item.id,
              (e) => e.copyWith(
                messageKey: 'notifications_started_following',
                action: _NotificationAction.followBack,
              ),
            );
          }
        } catch (_) {
          if (mounted) _replaceItem(item.id, (_) => item);
        } finally {
          _busy.remove(item.id);
          unawaited(_watcher.refresh());
        }
      case _NotificationAction.followBack:
        final userId = item.actorUserId?.trim() ?? '';
        if (userId.isEmpty || _busy.contains(item.id)) return;
        if (_stateFor(item.id) != _ActionState.idle) return;
        _busy.add(item.id);
        // Assume public follow succeeds — don't flash "istek gönderildi".
        setState(() {
          _actionStates.remove(item.id);
          _items = [
            for (final existing in _items)
              if (existing.id == item.id)
                existing.copyWith(clearAction: true)
              else
                existing,
          ];
        });
        try {
          final result = await auth.followUser(userId);
          if (!mounted) return;
          if (result.status == 'pending') {
            setState(() {
              _actionStates[item.id] = _ActionState.requestSent;
              _items = [
                for (final existing in _items)
                  if (existing.id == item.id)
                    existing.copyWith(action: _NotificationAction.requestSent)
                  else
                    existing,
              ];
            });
          }
        } catch (_) {
          if (!mounted) return;
          setState(() {
            _actionStates.remove(item.id);
            _items = [
              for (final existing in _items)
                if (existing.id == item.id) item else existing,
            ];
          });
        } finally {
          _busy.remove(item.id);
          unawaited(_watcher.refresh());
        }
      case _NotificationAction.requestSent:
        return;
      case _NotificationAction.sendMessage:
        context.push(
          RoutePaths.chatDetail.path,
          extra: ChatDetailRouteArgs(
            name: item.displayName ?? item.username,
            username: item.username,
            avatarPath: item.avatarPath ?? AssetPaths.avatarYou,
          ),
        );
    }
  }

  Future<void> _openStory(_NotificationItem item) async {
    final storyId = item.objectId?.trim() ?? '';
    if (storyId.isEmpty) return;
    // story_like: recipient owns the story; open their real ring.
    await openStoryById(context, storyId: storyId);
  }

  Future<void> _openActor(_NotificationItem item) async {
    if (item.isStoryLike && (item.thumbnailPath ?? '').isNotEmpty) {
      _openStory(item);
      return;
    }
    final username = item.username.trim();
    if (username.isEmpty) return;
    await openUserProfile(
      context,
      username,
      seed: PublicUserProfile.skeleton(
        username: username,
        name: item.displayName ?? '',
        avatarPath: item.avatarPath ?? '',
        userId: item.actorUserId ?? '',
      ),
    );
  }

  Future<void> _deleteNotification(_NotificationItem item) async {
    if (_removing.contains(item.id)) return;

    setState(() {
      _removing.add(item.id);
      if (_openedSwipeId == item.id) _openedSwipeId = null;
    });

    try {
      await getIt<AuthRepository>().deleteNotification(item.id);
      _deleted.add(item.id);
      _watcher.markSeen(item.id);
    } catch (_) {
      if (!mounted) return;
      // Let the row spring back open and tell the user it didn't stick.
      setState(() => _removing.remove(item.id));
      unawaited(_watcher.refresh());
      AppSnackbar.instance.show(
        context,
        'notifications_delete_failed'.tr(),
        isError: true,
      );
    }
  }

  void _onRowRemoved(String id) {
    if (!mounted) return;
    setState(() {
      _items = [for (final e in _items) if (e.id != id) e];
      _removing.remove(id);
      _actionStates.remove(id);
    });
    unawaited(_watcher.refresh());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    behavior: HitTestBehavior.opaque,
                    child: const AppIcon(AssetPaths.iconArrowLeft, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'notifications_title'.tr(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      letterSpacing: -0.4,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const AppLoading()
                  : _items.isEmpty
                  ? Center(
                      child: Text(
                        'notifications_empty'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    )
                  : ListView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        _Section(
                          title: 'notifications_highlights'.tr(),
                          items: _items,
                          actionStateFor: _stateFor,
                          removingIds: _removing,
                          onRowRemoved: _onRowRemoved,
                          openedSwipeId: _openedSwipeId,
                          onOpenChanged: (id, open) {
                            setState(() {
                              _openedSwipeId = open ? id : null;
                            });
                          },
                          onAction: _onAction,
                          onOpenActor: _openActor,
                          onOpenStory: _openStory,
                          onDelete: _deleteNotification,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
    required this.actionStateFor,
    required this.removingIds,
    required this.onRowRemoved,
    required this.openedSwipeId,
    required this.onOpenChanged,
    required this.onAction,
    required this.onOpenActor,
    required this.onOpenStory,
    required this.onDelete,
  });

  final String title;
  final List<_NotificationItem> items;
  final _ActionState Function(String id) actionStateFor;
  final Set<String> removingIds;
  final ValueChanged<String> onRowRemoved;
  final String? openedSwipeId;
  final void Function(String id, bool open) onOpenChanged;
  final ValueChanged<_NotificationItem> onAction;
  final ValueChanged<_NotificationItem> onOpenActor;
  final ValueChanged<_NotificationItem> onOpenStory;
  final ValueChanged<_NotificationItem> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1,
            letterSpacing: -0.32,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < items.length; i++)
          _CollapsibleRow(
            key: ValueKey(items[i].id),
            removing: removingIds.contains(items[i].id),
            onRemoved: () => onRowRemoved(items[i].id),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: i == items.length - 1 ? 0 : 16,
              ),
              child: ChatSwipeDeleteTile(
                isOpen: openedSwipeId == items[i].id,
                onOpenChanged: (open) => onOpenChanged(items[i].id, open),
                onDeleteTap: () => onDelete(items[i]),
                child: _NotificationTile(
                  item: items[i],
                  actionState: actionStateFor(items[i].id),
                  onAction: () => onAction(items[i]),
                  onOpenActor: () => onOpenActor(items[i]),
                  onOpenStory: () => onOpenStory(items[i]),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Collapses its child to zero height before the row leaves the list, so a
/// delete reads as the row folding away instead of blinking out.
class _CollapsibleRow extends StatefulWidget {
  const _CollapsibleRow({
    required this.removing,
    required this.onRemoved,
    required this.child,
    super.key,
  });

  final bool removing;
  final VoidCallback onRemoved;
  final Widget child;

  @override
  State<_CollapsibleRow> createState() => _CollapsibleRowState();
}

class _CollapsibleRowState extends State<_CollapsibleRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );

  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void didUpdateWidget(covariant _CollapsibleRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.removing == oldWidget.removing) return;
    if (widget.removing) {
      _controller.reverse().then((_) {
        if (mounted && widget.removing) widget.onRemoved();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _curved,
      alignment: Alignment.topCenter,
      child: FadeTransition(opacity: _curved, child: widget.child),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.actionState,
    required this.onAction,
    required this.onOpenActor,
    required this.onOpenStory,
  });

  final _NotificationItem item;
  final _ActionState actionState;
  final VoidCallback onAction;
  final VoidCallback onOpenActor;
  final VoidCallback onOpenStory;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onOpenActor,
          behavior: HitTestBehavior.opaque,
          child: _Leading(item: item),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: onOpenActor,
            behavior: HitTestBehavior.opaque,
            child: _NotificationText(item: item),
          ),
        ),
        if (item.action != null) ...[
          const SizedBox(width: 10),
          _ActionButton(
            action: item.action!,
            state: actionState,
            onTap: onAction,
          ),
        ] else if (item.isStoryLike && item.thumbnailPath != null) ...[
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onOpenStory,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.thumbnailPath!,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(width: 44, height: 44),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({required this.item});

  final _NotificationItem item;

  @override
  Widget build(BuildContext context) {
    if (item.leading == _NotificationLeading.heartCircle) {
      return const AppIcon(AssetPaths.iconHeartCircleFilled, size: 60);
    }

    final avatar = ProfileAvatar(path: item.avatarPath ?? '', size: 60);
    if (!item.showLikeBadge) return avatar;

    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.zoviOrange,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.favorite_rounded,
                size: 11,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationText extends StatelessWidget {
  const _NotificationText({required this.item});

  final _NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final time = _NotificationsViewState.formatRelativeTime(item.createdAt);
    final timeSuffix = time.isEmpty ? '' : ' $time';
    const usernameStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: -0.32,
      color: AppColors.black,
    );
    final bodyStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.2,
      letterSpacing: -0.32,
      color: AppColors.black.withValues(alpha: 0.5),
    );

    // Aggregated likes: "**120 kişi** story'yi beğendi."
    if (item.count != null) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'notifications_people_liked_story_count'.tr(
                namedArgs: {'count': '${item.count}'},
              ),
              style: usernameStyle,
            ),
            TextSpan(
              text:
                  ' ${'notifications_people_liked_story_rest'.tr()}$timeSuffix',
              style: bodyStyle,
            ),
          ],
        ),
      );
    }

    final message = item.messageKey.tr();

    if (item.username.isEmpty) {
      return Text('$message$timeSuffix', style: bodyStyle);
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: item.username, style: usernameStyle),
          TextSpan(text: ' $message$timeSuffix', style: bodyStyle),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.state,
    required this.onTap,
  });

  final _NotificationAction action;
  final _ActionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCompleted =
        state != _ActionState.idle || action == _NotificationAction.requestSent;
    final isPrimary =
        (action == _NotificationAction.followBack ||
            action == _NotificationAction.acceptRequest) &&
        !isCompleted;

    final label = switch (state) {
      _ActionState.followRequestSent => 'notifications_request_sent'.tr(),
      _ActionState.requestSent => 'notifications_request_sent'.tr(),
      _ActionState.idle => switch (action) {
        _NotificationAction.followBack => 'notifications_follow_back'.tr(),
        _NotificationAction.acceptRequest =>
          'notifications_accept_request'.tr(),
        _NotificationAction.sendMessage => 'notifications_send_message'.tr(),
        _NotificationAction.requestSent => 'notifications_request_sent'.tr(),
      },
    };

    return GestureDetector(
      onTap: isCompleted && action != _NotificationAction.sendMessage
          ? null
          : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.zoviOrange
              : AppColors.zoviOrange.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1,
            letterSpacing: -0.28,
            color: isPrimary ? AppColors.white : AppColors.zoviOrange,
          ),
        ),
      ),
    );
  }
}
