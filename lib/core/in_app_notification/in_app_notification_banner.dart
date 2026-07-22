import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:zovi/core/in_app_notification/in_app_notification_data.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/profile_avatar.dart';

class InAppNotificationBanner extends StatefulWidget {
  const InAppNotificationBanner({
    required this.data,
    required this.onDismiss,
    required this.onAction,
    super.key,
  });

  final InAppNotificationData data;
  final VoidCallback onDismiss;
  final VoidCallback onAction;

  @override
  State<InAppNotificationBanner> createState() =>
      _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<InAppNotificationBanner> {
  bool _followRequestSent = false;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 8;

    return Material(
      type: MaterialType.transparency,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, top, 16, 0),
          child: GestureDetector(
            onTap: widget.data.action == InAppNotificationAction.openStory ||
                    widget.data.action == InAppNotificationAction.openChat
                ? widget.onAction
                : null,
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) < -200) {
                widget.onDismiss();
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 80),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0x80262626),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      ProfileAvatar(
                        path: widget.data.avatarPath,
                        size: 60,
                        showGradientRing: widget.data.showGradientRing,
                        ringGapColor: const Color(0xFF262626),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _MessageText(data: widget.data)),
                      if (_hasTrailing) ...[
                        const SizedBox(width: 10),
                        _Trailing(
                          data: widget.data,
                          followRequestSent: _followRequestSent,
                          onFriendRequest: widget.onAction,
                          onFollowBack: () {
                            if (_followRequestSent) return;
                            setState(() => _followRequestSent = true);
                            widget.onAction();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasTrailing {
    return switch (widget.data.action) {
      InAppNotificationAction.friendRequest ||
      InAppNotificationAction.followBack =>
        true,
      _ => false,
    };
  }
}

class _MessageText extends StatelessWidget {
  const _MessageText({required this.data});

  final InAppNotificationData data;

  @override
  Widget build(BuildContext context) {
    final message = data.messageKey.tr();
    final timeSuffix = data.time.isEmpty ? '' : ' ${data.time}';

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: data.username,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1,
              letterSpacing: -0.32,
              color: AppColors.white,
            ),
          ),
          TextSpan(
            text: ' $message$timeSuffix',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.2,
              letterSpacing: -0.32,
              color: AppColors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _Trailing extends StatelessWidget {
  const _Trailing({
    required this.data,
    required this.followRequestSent,
    required this.onFriendRequest,
    required this.onFollowBack,
  });

  final InAppNotificationData data;
  final bool followRequestSent;
  final VoidCallback onFriendRequest;
  final VoidCallback onFollowBack;

  @override
  Widget build(BuildContext context) {
    return switch (data.action) {
      InAppNotificationAction.friendRequest => GestureDetector(
          onTap: onFriendRequest,
          behavior: HitTestBehavior.opaque,
          child: const AppIcon(AssetPaths.iconNotif, size: 32),
        ),
      InAppNotificationAction.followBack => GestureDetector(
          onTap: followRequestSent ? null : onFollowBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: followRequestSent
                  ? AppColors.zoviOrange.withValues(alpha: 0.18)
                  : AppColors.zoviOrange,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              followRequestSent
                  ? 'notifications_follow_request_sent'.tr()
                  : 'notifications_follow_back'.tr(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1,
                letterSpacing: -0.28,
                color: followRequestSent
                    ? AppColors.zoviOrange
                    : AppColors.white,
              ),
            ),
          ),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
