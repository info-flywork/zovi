import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/app_confirm_dialog.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/profile_avatar.dart';
import 'package:zovi/domain/chat/chat_repository.dart';
import 'package:zovi/presentation/chat/model/chat_detail_exit_store.dart';
import 'package:zovi/presentation/chat/model/chat_detail_route_args.dart';
import 'package:zovi/presentation/chat/model/chat_request_item.dart';
import 'package:zovi/presentation/chat/view/widgets/chat_last_message_preview.dart';
import 'package:zovi/presentation/chat/view/widgets/chat_swipe_delete_tile.dart';

const _deleteRequestRed = Color(0xFFEC1C24);

@immutable
final class ChatRequestsView extends StatefulWidget {
  const ChatRequestsView({required this.requests, super.key});

  final List<ChatRequestItem> requests;

  @override
  State<ChatRequestsView> createState() => _ChatRequestsViewState();
}

final class _ChatRequestsViewState extends State<ChatRequestsView> {
  static const _removeDuration = Duration(milliseconds: 280);

  late List<ChatRequestItem> _requests;
  final _listKey = GlobalKey<AnimatedListState>();
  String? _openedSwipeUsername;

  @override
  void initState() {
    super.initState();
    _requests = List<ChatRequestItem>.from(widget.requests);
  }

  void _popWithResult() => context.pop(_requests);

  Future<void> _deleteAll() async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'chat_request_delete_all_title'.tr(),
      subtitle: 'chat_request_delete_all_subtitle'.tr(),
      confirmLabel: 'chat_delete_confirm'.tr(),
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _requests = [];
      _openedSwipeUsername = null;
    });
    unawaited(getIt<ChatRepository>().deleteAllRequests());
  }

  Future<void> _confirmDeleteRequest(ChatRequestItem request) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'chat_request_delete_title'.tr(),
      subtitle: 'chat_request_delete_subtitle'.tr(),
      confirmLabel: 'chat_delete_confirm'.tr(),
    );
    if (!confirmed || !mounted) return;

    final index = _requests.indexWhere(
      (r) => r.conversationId == request.conversationId,
    );
    if (index < 0) return;

    final removed = _requests.removeAt(index);
    _openedSwipeUsername = null;

    _listKey.currentState?.removeItem(
      index,
      (context, animation) =>
          _RequestRemoveTile(request: removed, animation: animation),
      duration: _removeDuration,
    );

    if (_requests.isEmpty) {
      Future<void>.delayed(_removeDuration, () {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }

    try {
      await getIt<ChatRepository>().deleteConversation(request.conversationId);
    } catch (_) {
      // List already updated; next open refreshes from server.
    }
  }

  Future<void> _openRequest(ChatRequestItem request) async {
    if (_openedSwipeUsername != null) {
      setState(() => _openedSwipeUsername = null);
      return;
    }
    final result = await context.push<String?>(
      RoutePaths.chatDetail.path,
      extra: ChatDetailRouteArgs(
        name: request.name,
        username: request.username,
        avatarPath: request.avatarPath,
        userId: request.userId,
        conversationId: request.conversationId,
        isRequest: true,
      ),
    );
    if (!mounted) return;
    final effective =
        result ?? ChatDetailExitStore.take(request.conversationId);
    final index = _requests.indexWhere(
      (r) => r.conversationId == request.conversationId,
    );
    if (index < 0) return;

    if (effective == 'accepted' || effective == 'blocked') {
      final removed = _requests.removeAt(index);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) =>
            _RequestRemoveTile(request: removed, animation: animation),
        duration: _removeDuration,
      );
      if (_requests.isEmpty) {
        Future<void>.delayed(_removeDuration, () {
          if (mounted) setState(() {});
        });
      } else {
        setState(() {});
      }
      return;
    }

    setState(() {
      _requests[index] = _requests[index].copyWith(isUnread: false);
    });
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _popWithResult,
                    behavior: HitTestBehavior.opaque,
                    child: const AppIcon(AssetPaths.iconBack, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'chat_request_title'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1,
                      letterSpacing: -0.32,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ),
            if (_requests.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'chat_request_message_count'.tr(
                    namedArgs: {'count': '${_requests.length}'},
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    letterSpacing: -0.32,
                    color: AppColors.black,
                  ),
                ),
              ),
            Expanded(
              child: _requests.isEmpty
                  ? const _RequestEmptyState()
                  : AnimatedList(
                      key: _listKey,
                      clipBehavior: Clip.none,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
                      initialItemCount: _requests.length,
                      itemBuilder: (context, index, animation) {
                        final request = _requests[index];
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            index == _requests.length - 1 ? 0 : 16,
                          ),
                          child: ChatListItemTransition(
                            animation: animation,
                            child: ChatSwipeDeleteTile(
                              isOpen:
                                  _openedSwipeUsername == request.username,
                              onOpenChanged: (open) {
                                setState(() {
                                  _openedSwipeUsername =
                                      open ? request.username : null;
                                });
                              },
                              onDeleteTap: () =>
                                  _confirmDeleteRequest(request),
                              child: _RequestTile(
                                request: request,
                                onTap: () => _openRequest(request),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (_requests.isNotEmpty)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Center(
                    child: GestureDetector(
                      onTap: _deleteAll,
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        'chat_request_delete_all'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1,
                          letterSpacing: -0.32,
                          color: _deleteRequestRed,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

@immutable
final class _RequestRemoveTile extends StatelessWidget {
  const _RequestRemoveTile({required this.request, required this.animation});

  final ChatRequestItem request;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return ChatListItemTransition(
      animation: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.12, 0),
          end: Offset.zero,
        ).animate(animation),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _RequestTile(request: request, onTap: () {}),
        ),
      ),
    );
  }
}

@immutable
final class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request, required this.onTap});

  final ChatRequestItem request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          ProfileAvatar(path: request.avatarPath, size: 58),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    letterSpacing: -0.32,
                    color: AppColors.deepRoast,
                  ),
                ),
                const SizedBox(height: 4),
                ChatLastMessagePreview(
                  preview: request.preview,
                  isUnread: request.isUnread,
                ),
              ],
            ),
          ),
          if (request.isUnread) ...[
            const SizedBox(width: 10),
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: AppColors.zoviOrange,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

@immutable
final class _RequestEmptyState extends StatelessWidget {
  const _RequestEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon(AssetPaths.iconRequestEmpty, size: 98),
            const SizedBox(height: 20),
            Text(
              'chat_request_empty_title'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                height: 1,
                letterSpacing: -0.48,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'chat_request_empty_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 1.2,
                letterSpacing: -0.32,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
