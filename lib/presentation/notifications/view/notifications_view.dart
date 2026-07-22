import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/chat/model/chat_detail_route_args.dart';
import 'package:zovi/presentation/stories/model/story_detail_route_args.dart';

enum _NotificationAction { followBack, sendMessage, requestBack }

enum _NotificationLeading { avatar, heartCircle }

enum _ActionState { idle, followRequestSent, requestSent }

class _NotificationItem {
  const _NotificationItem({
    required this.id,
    required this.username,
    required this.messageKey,
    required this.time,
    required this.leading,
    this.avatarPath,
    this.action,
    this.thumbnailPath,
    this.showLikeBadge = false,
    this.count,
    this.displayName,
  });

  final String id;
  final String username;
  final String messageKey;
  final String time;
  final _NotificationLeading leading;
  final String? avatarPath;
  final _NotificationAction? action;
  final String? thumbnailPath;
  final bool showLikeBadge;
  final int? count;
  final String? displayName;
}

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  static const _highlights = [
    _NotificationItem(
      id: 'h1',
      username: 'jessica.3712',
      displayName: 'Jessica Blues',
      messageKey: 'notifications_started_following',
      time: '6h',
      leading: _NotificationLeading.avatar,
      avatarPath: AssetPaths.avatarJessica,
      action: _NotificationAction.followBack,
    ),
    _NotificationItem(
      id: 'h2',
      username: 'sonabllack',
      displayName: 'Sona Black',
      messageKey: 'notifications_started_following',
      time: '12h',
      leading: _NotificationLeading.avatar,
      avatarPath: AssetPaths.avatarSona,
      action: _NotificationAction.followBack,
    ),
    _NotificationItem(
      id: 'h3',
      username: 'sonabllack',
      displayName: 'Sona Black',
      messageKey: 'notifications_liked_story',
      time: '1d',
      leading: _NotificationLeading.avatar,
      avatarPath: AssetPaths.avatarSona,
      thumbnailPath: AssetPaths.storyJulia,
      showLikeBadge: true,
    ),
    _NotificationItem(
      id: 'h4',
      username: 'sonabllack',
      displayName: 'Sona Black',
      messageKey: 'notifications_checked_in',
      time: '',
      leading: _NotificationLeading.avatar,
      avatarPath: AssetPaths.avatarSona,
    ),
  ];

  static const _yesterday = [
    _NotificationItem(
      id: 'y1',
      username: 'jessica.3712',
      displayName: 'Jessica Blues',
      messageKey: 'notifications_accepted_friend',
      time: '',
      leading: _NotificationLeading.avatar,
      avatarPath: AssetPaths.avatarJessica,
    ),
    _NotificationItem(
      id: 'y2',
      username: 'sonabllack',
      displayName: 'Sona Black',
      messageKey: 'notifications_accepted_friend_short',
      time: '',
      leading: _NotificationLeading.avatar,
      avatarPath: AssetPaths.avatarSona,
      action: _NotificationAction.sendMessage,
    ),
    _NotificationItem(
      id: 'y3',
      username: 'Fiona',
      displayName: 'Fiona',
      messageKey: 'notifications_friend_request',
      time: '',
      leading: _NotificationLeading.avatar,
      avatarPath: AssetPaths.avatarNova,
      action: _NotificationAction.requestBack,
    ),
  ];

  static const _last7Days = [
    _NotificationItem(
      id: 'l1',
      username: '',
      messageKey: 'notifications_people_liked_story',
      time: '',
      leading: _NotificationLeading.heartCircle,
      thumbnailPath: AssetPaths.checkinPlace,
      count: 120,
    ),
  ];

  final Map<String, _ActionState> _actionStates = {};

  _ActionState _stateFor(String id) => _actionStates[id] ?? _ActionState.idle;

  void _onAction(_NotificationItem item) {
    final action = item.action;
    if (action == null) return;

    switch (action) {
      case _NotificationAction.followBack:
        if (_stateFor(item.id) != _ActionState.idle) return;
        setState(() => _actionStates[item.id] = _ActionState.followRequestSent);
      case _NotificationAction.requestBack:
        if (_stateFor(item.id) != _ActionState.idle) return;
        setState(() => _actionStates[item.id] = _ActionState.requestSent);
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

  void _openStory(_NotificationItem item) {
    final imagePath = item.thumbnailPath;
    if (imagePath == null) return;

    final story = StoryMediaItem(
      imagePath: imagePath,
      label: item.displayName?.isNotEmpty == true
          ? item.displayName!
          : (item.username.isNotEmpty ? item.username : 'You'),
      avatarPath: item.avatarPath ?? AssetPaths.avatarYou,
      isReel: false,
    );

    context.push(
      RoutePaths.storyDetail.path,
      extra: StoryDetailRouteArgs(items: [story], initialIndex: 0),
    );
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
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  _Section(
                    title: 'notifications_highlights'.tr(),
                    items: _highlights,
                    actionStateFor: _stateFor,
                    onAction: _onAction,
                    onOpenStory: _openStory,
                  ),
                  const SizedBox(height: 24),
                  _Section(
                    title: 'notifications_yesterday'.tr(),
                    items: _yesterday,
                    actionStateFor: _stateFor,
                    onAction: _onAction,
                    onOpenStory: _openStory,
                  ),
                  const SizedBox(height: 24),
                  _Section(
                    title: 'notifications_last_7_days'.tr(),
                    items: _last7Days,
                    actionStateFor: _stateFor,
                    onAction: _onAction,
                    onOpenStory: _openStory,
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
    required this.onAction,
    required this.onOpenStory,
  });

  final String title;
  final List<_NotificationItem> items;
  final _ActionState Function(String id) actionStateFor;
  final ValueChanged<_NotificationItem> onAction;
  final ValueChanged<_NotificationItem> onOpenStory;

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
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _NotificationTile(
            item: items[i],
            actionState: actionStateFor(items[i].id),
            onAction: () => onAction(items[i]),
            onOpenStory: () => onOpenStory(items[i]),
          ),
        ],
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.actionState,
    required this.onAction,
    required this.onOpenStory,
  });

  final _NotificationItem item;
  final _ActionState actionState;
  final VoidCallback onAction;
  final VoidCallback onOpenStory;

  bool get _isStoryLike =>
      item.showLikeBadge ||
      item.leading == _NotificationLeading.heartCircle ||
      item.messageKey == 'notifications_liked_story' ||
      item.messageKey == 'notifications_people_liked_story';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isStoryLike && item.thumbnailPath != null ? onOpenStory : null,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Leading(item: item),
          const SizedBox(width: 12),
          Expanded(child: _NotificationText(item: item)),
          if (item.action != null) ...[
            const SizedBox(width: 10),
            _ActionButton(
              action: item.action!,
              state: actionState,
              onTap: onAction,
            ),
          ],
          if (item.thumbnailPath != null) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onOpenStory,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  item.thumbnailPath!,
                  width: 54,
                  height: 55,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ],
      ),
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

    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: Image.asset(
              item.avatarPath!,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          if (item.showLikeBadge)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.logoutRed,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const AppIcon(AssetPaths.iconHeart2, size: 12),
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
    final message = item.count != null
        ? item.messageKey.tr(namedArgs: {'count': '${item.count}'})
        : item.messageKey.tr();

    if (item.username.isEmpty) {
      return Text(
        message,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.2,
          letterSpacing: -0.32,
          color: AppColors.black,
        ),
      );
    }

    final timeSuffix = item.time.isEmpty ? '' : ' ${item.time}';

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: item.username,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.2,
              letterSpacing: -0.32,
              color: AppColors.black,
            ),
          ),
          TextSpan(
            text: ' $message$timeSuffix',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.2,
              letterSpacing: -0.32,
              color: AppColors.black.withValues(alpha: 0.5),
            ),
          ),
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
    final isCompleted = state != _ActionState.idle;
    final isPrimary = action == _NotificationAction.followBack && !isCompleted;

    final label = switch (state) {
      _ActionState.followRequestSent =>
        'notifications_follow_request_sent'.tr(),
      _ActionState.requestSent => 'notifications_request_sent'.tr(),
      _ActionState.idle => switch (action) {
        _NotificationAction.followBack => 'notifications_follow_back'.tr(),
        _NotificationAction.sendMessage => 'notifications_send_message'.tr(),
        _NotificationAction.requestBack => 'notifications_request_back'.tr(),
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
