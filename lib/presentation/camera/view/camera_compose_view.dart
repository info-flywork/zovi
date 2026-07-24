import 'dart:io';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:zovi/core/in_app_notification/app_in_app_notification.dart';
import 'package:zovi/core/in_app_notification/in_app_notification_data.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/camera/model/camera_compose_route_args.dart';
import 'package:zovi/presentation/chat/view/widgets/chat_sticker_sheet.dart';

enum _ComposeAudience { friendsOnly, public }

class CameraComposeView extends StatefulWidget {
  const CameraComposeView({required this.args, super.key});

  final CameraComposeRouteArgs args;

  @override
  State<CameraComposeView> createState() => _CameraComposeViewState();
}

class _CameraComposeViewState extends State<CameraComposeView> {
  var _saving = false;
  var _audience = _ComposeAudience.friendsOnly;
  StampItem? _selectedStamp;

  CameraComposeRouteArgs get args => widget.args;

  void _showBanner({
    required String titleKey,
    String? subtitleKey,
    required String icon,
  }) {
    AppInAppNotification.instance.show(
      InAppNotificationData(
        username: '',
        messageKey: titleKey,
        subtitleKey: subtitleKey,
        avatarPath: AssetPaths.avatarYou,
        leadingIconPath: icon,
        useFullTitle: true,
      ),
      alignment: Alignment.topCenter,
    );
  }

  Future<void> _saveToGallery() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final permission = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          iosAccessLevel: IosAccessLevel.readWrite,
        ),
      );
      if (!permission.hasAccess) {
        if (!mounted) return;
        _showBanner(
          titleKey: 'camera_compose_save_permission',
          subtitleKey: 'camera_compose_save_permission_subtitle',
          icon: AssetPaths.iconImportArrow,
        );
        return;
      }

      final filename = 'zovi_${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (args.isAsset) {
        final data = await rootBundle.load(args.imagePath);
        await PhotoManager.editor.saveImage(
          data.buffer.asUint8List(),
          filename: filename,
        );
      } else {
        final file = File(args.imagePath);
        if (!await file.exists()) {
          throw StateError('missing file');
        }
        await PhotoManager.editor.saveImageWithPath(
          args.imagePath,
          title: filename,
        );
      }

      if (!mounted) return;
      _showBanner(
        titleKey: 'camera_compose_saved',
        subtitleKey: 'camera_compose_saved_subtitle',
        icon: AssetPaths.iconImportArrow,
      );
    } catch (_) {
      if (!mounted) return;
      _showBanner(
        titleKey: 'camera_compose_save_failed',
        subtitleKey: 'camera_compose_save_failed_subtitle',
        icon: AssetPaths.iconImportArrow,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggleAudience() {
    setState(() {
      _audience = _audience == _ComposeAudience.friendsOnly
          ? _ComposeAudience.public
          : _ComposeAudience.friendsOnly;
    });
  }

  void _comingSoon() {
    _showBanner(
      titleKey: 'coming_soon',
      subtitleKey: 'coming_soon_subtitle',
      icon: AssetPaths.iconSetting,
    );
  }

  Future<void> _openStampSheet() async {
    final stamp = await showChatStickerSheet(
      context,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.8,
    );
    if (!mounted || stamp == null) return;
    setState(() => _selectedStamp = stamp);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final isPublic = _audience == _ComposeAudience.public;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: args.isAsset
                  ? Image.asset(args.imagePath, fit: BoxFit.cover)
                  : Image.file(File(args.imagePath), fit: BoxFit.cover),
            ),
            if (_selectedStamp != null)
              Positioned(
                right: 24,
                bottom: 140 + bottomInset,
                child: Image.asset(
                  _selectedStamp!.imagePath,
                  width: 96,
                  height: 96,
                  fit: BoxFit.contain,
                ),
              ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          behavior: HitTestBehavior.opaque,
                          child: const AppIcon(AssetPaths.iconCloose, size: 32),
                        ),
                        const Spacer(),
                        Column(
                          children: [
                            _ToolIcon(
                              asset: AssetPaths.iconSetting,
                              onTap: _comingSoon,
                            ),
                            const SizedBox(height: 12),
                            _ToolIcon(
                              asset: AssetPaths.iconTextAa,
                              onTap: _comingSoon,
                            ),
                            const SizedBox(height: 12),
                            _ToolIcon(
                              asset: AssetPaths.iconSticker,
                              onTap: _openStampSheet,
                            ),
                            const SizedBox(height: 12),
                            _ToolIcon(
                              asset: AssetPaths.iconMusicNote,
                              onTap: _comingSoon,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        color: AppColors.black.withValues(alpha: 0.70),
                        padding: EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          16 + bottomInset,
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _saving ? null : _saveToGallery,
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.black.withValues(
                                    alpha: 0.50,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: _saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.white,
                                        ),
                                      )
                                    : const AppIcon(
                                        AssetPaths.iconImportArrow,
                                        size: 24,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: _toggleAudience,
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  height: 44,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.black.withValues(
                                      alpha: 0.40,
                                    ),
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  alignment: Alignment.center,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 280),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    transitionBuilder: (child, animation) {
                                      final offset = Tween<Offset>(
                                        begin: const Offset(0, 0.35),
                                        end: Offset.zero,
                                      ).animate(animation);
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: offset,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Row(
                                      key: ValueKey(_audience),
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AppIcon(
                                          isPublic
                                              ? AssetPaths.iconPublic
                                              : AssetPaths.iconAiUsers,
                                          size: 24,
                                          color: AppColors.white,
                                        ),
                                        const SizedBox(width: 10),
                                        Flexible(
                                          child: Text(
                                            isPublic
                                                ? 'camera_compose_public'.tr()
                                                : 'camera_compose_friends_only'
                                                      .tr(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              height: 1,
                                              letterSpacing: -0.32,
                                              color: AppColors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {
                                _showBanner(
                                  titleKey: 'camera_compose_shared',
                                  subtitleKey: 'camera_compose_shared_subtitle',
                                  icon: AssetPaths.iconSendPlane,
                                );
                                context.go(RoutePaths.home.path);
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.zoviOrange,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'camera_compose_share'.tr(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        height: 1,
                                        letterSpacing: -0.32,
                                        color: AppColors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const AppIcon(
                                      AssetPaths.iconSendPlane,
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _ToolIcon extends StatelessWidget {
  const _ToolIcon({required this.asset, required this.onTap});

  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.black.withValues(alpha: 0.35),
        ),
        alignment: Alignment.center,
        child: AppIcon(asset, size: 24, color: AppColors.white),
      ),
    );
  }
}
