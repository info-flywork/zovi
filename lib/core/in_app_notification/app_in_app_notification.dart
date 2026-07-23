import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/in_app_notification/in_app_notification_banner.dart';
import 'package:zovi/core/in_app_notification/in_app_notification_data.dart';
import 'package:zovi/core/router/app_router.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/chat/model/chat_detail_route_args.dart';
import 'package:zovi/presentation/stories/model/story_detail_route_args.dart';

class AppInAppNotification {
  AppInAppNotification._();
  static final AppInAppNotification instance = AppInAppNotification._();

  OverlayEntry? _entry;
  Timer? _autoHide;
  _InAppNotificationHostState? _host;

  bool get isVisible => _entry != null;

  void show(
    InAppNotificationData data, {
    Duration displayDuration = const Duration(seconds: 4),
  }) {
    final context = AppRouter.rootKey.currentContext;
    if (context == null) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true) ??
        AppRouter.rootKey.currentState?.overlay;
    if (overlay == null) return;

    // Önceki banner’ı senkron kaldır; async race olmasın.
    _autoHide?.cancel();
    _autoHide = null;
    _entry?.remove();
    _entry = null;
    _host = null;

    _entry = OverlayEntry(
      builder: (context) {
        return _InAppNotificationHost(
          data: data,
          onReady: (host) => _host = host,
          onDismiss: () => hide(),
          onAction: () => _handleAction(data),
        );
      },
    );

    overlay.insert(_entry!);

    _autoHide = Timer(displayDuration, hide);
  }

  Future<void> hide({bool immediate = false}) async {
    _autoHide?.cancel();
    _autoHide = null;

    final entry = _entry;
    final host = _host;
    _entry = null;
    _host = null;

    if (entry == null) return;

    if (!immediate && host != null) {
      await host.reverse();
    }

    entry.remove();
  }

  void _extendDisplay(Duration duration) {
    _autoHide?.cancel();
    _autoHide = Timer(duration, hide);
  }

  void _handleAction(InAppNotificationData data) {
    final context = AppRouter.rootKey.currentContext;
    if (context == null) return;

    switch (data.action) {
      case InAppNotificationAction.friendRequest:
        _extendDisplay(const Duration(milliseconds: 900));
      case InAppNotificationAction.followBack:
        _extendDisplay(const Duration(milliseconds: 1200));
      case InAppNotificationAction.openChat:
        hide(immediate: true);
        context.push(
          RoutePaths.chatDetail.path,
          extra: ChatDetailRouteArgs(
            name: data.displayName ?? data.username,
            username: data.username,
            avatarPath: data.avatarPath,
          ),
        );
      case InAppNotificationAction.openStory:
        hide(immediate: true);
        final imagePath = data.storyImagePath ?? AssetPaths.storyJulia;
        context.push(
          RoutePaths.storyDetail.path,
          extra: StoryDetailRouteArgs(
            items: [
              StoryMediaItem(
                imagePath: imagePath,
                label: data.displayName ?? data.username,
                avatarPath: data.avatarPath,
                isReel: false,
              ),
            ],
            initialIndex: 0,
          ),
        );
      case InAppNotificationAction.none:
        break;
    }
  }
}

class _InAppNotificationHost extends StatefulWidget {
  const _InAppNotificationHost({
    required this.data,
    required this.onReady,
    required this.onDismiss,
    required this.onAction,
  });

  final InAppNotificationData data;
  final ValueChanged<_InAppNotificationHostState> onReady;
  final VoidCallback onDismiss;
  final VoidCallback onAction;

  @override
  State<_InAppNotificationHost> createState() => _InAppNotificationHostState();
}

class _InAppNotificationHostState extends State<_InAppNotificationHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    reverseDuration: const Duration(milliseconds: 260),
  );

  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -1.15),
    end: Offset.zero,
  ).animate(_curved);

  late final Animation<double> _fade = Tween<double>(
    begin: 0,
    end: 1,
  ).animate(_curved);

  late final Animation<double> _scale = Tween<double>(
    begin: 0.94,
    end: 1,
  ).animate(_curved);

  @override
  void initState() {
    super.initState();
    widget.onReady(this);
    // İlk frame kapalı başlasın, sonra animasyonla açılsın.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  Future<void> reverse() async {
    if (!mounted) return;
    try {
      await _controller.reverse();
    } catch (_) {}
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 8;

    return Material(
      type: MaterialType.transparency,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, top, 16, 0),
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                alignment: Alignment.topCenter,
                child: InAppNotificationBanner(
                  data: widget.data,
                  onDismiss: widget.onDismiss,
                  onAction: widget.onAction,
                  embedInHost: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
