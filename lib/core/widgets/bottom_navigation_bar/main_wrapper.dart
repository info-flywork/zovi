import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/profile_avatar.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/home/bloc/home_bloc.dart';
import 'package:zovi/presentation/home/bloc/home_event.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// Floating bottom nav yaklaşık yüksekliği (içerik padding için).
  static const double navBarHeight = 72;

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  /// Nav item index → shell branch index (camera is a push, not a branch).
  static const _branchForNavItem = {0: 0, 2: 1, 3: 2, 4: 3};

  @override
  void initState() {
    super.initState();
    final repo = getIt<UserRepository>();
    if (repo.currentUserListenable.value == null) {
      unawaited(repo.getCurrentUser());
    }
  }

  int get _currentNavIndex {
    for (final entry in _branchForNavItem.entries) {
      if (entry.value == widget.navigationShell.currentIndex) return entry.key;
    }
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    if (index == 1) {
      context.push(RoutePaths.camera.path);
      return;
    }

    final branch = _branchForNavItem[index];
    if (branch == null) return;

    final wasOnBranch = branch == widget.navigationShell.currentIndex;
    widget.navigationShell.goBranch(branch, initialLocation: wasOnBranch);

    // IndexedStack keeps tabs mounted — don't refetch Stories (CDN/grid).
    if (branch == 0 && !wasOnBranch) {
      getIt<HomeBloc>().add(const HomeStarted());
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentNavIndex;
    final locale = context.locale;

    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          KeyedSubtree(
            key: ValueKey(locale.languageCode),
            child: widget.navigationShell,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                (MediaQuery.viewPaddingOf(context).bottom - 10).clamp(0.0, 40.0),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      _NavItem(
                        label: 'nav_map'.tr(),
                        icon: AssetPaths.iconLocationOutlined,
                        selected: currentIndex == 0,
                        onTap: () => _onTap(context, 0),
                      ),
                      _NavItem(
                        label: 'nav_camera'.tr(),
                        icon: AssetPaths.iconStampCamera,
                        selected: currentIndex == 1,
                        onTap: () => _onTap(context, 1),
                      ),
                      _NavItem(
                        label: 'nav_stories'.tr(),
                        icon: 'assets/icons/search-favorite.svg',
                        selected: currentIndex == 2,
                        onTap: () => _onTap(context, 2),
                      ),
                      _NavItem(
                        label: 'nav_chat'.tr(),
                        icon: AssetPaths.iconChat,
                        selected: currentIndex == 3,
                        onTap: () => _onTap(context, 3),
                      ),
                      ValueListenableBuilder<UserProfile?>(
                        valueListenable:
                            getIt<UserRepository>().currentUserListenable,
                        builder: (context, user, _) {
                          final hasPhoto = user?.hasPhoto ?? false;
                          return _NavItem(
                            label: 'nav_profile'.tr(),
                            selected: currentIndex == 4,
                            onTap: () => _onTap(context, 4),
                            avatarPath: hasPhoto ? user!.avatarPath : null,
                            icon: AssetPaths.iconProfile6,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.avatarPath,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? icon;
  final String? avatarPath;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.zoviOrange : AppColors.deepRoast;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (avatarPath != null)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? AppColors.zoviOrange
                          : AppColors.borderGray,
                      width: 2,
                    ),
                  ),
                  child: ProfileAvatar(path: avatarPath!, size: 24),
                )
              else
                AppIcon(icon!, size: 24, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
