import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';

class MainWrapper extends StatelessWidget {
  const MainWrapper({required this.child, super.key});

  final Widget child;

  /// Floating bottom nav yaklaşık yüksekliği (içerik padding için).
  static const double navBarHeight = 72;

  int _indexForLocation(String location) {
    if (location.startsWith(RoutePaths.stories.path)) return 2;
    if (location.startsWith(RoutePaths.chat.path)) return 3;
    if (location.startsWith(RoutePaths.profile.path)) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RoutePaths.home.path);
      case 1:
        context.push(RoutePaths.camera.path);
      case 2:
        context.go(RoutePaths.stories.path);
      case 3:
        context.go(RoutePaths.chat.path);
      case 4:
        context.go(RoutePaths.profile.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexForLocation(location);

    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          child,
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
                      _NavItem(
                        label: 'nav_profile'.tr(),
                        selected: currentIndex == 4,
                        onTap: () => _onTap(context, 4),
                        avatar: AssetPaths.avatarYou,
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
    this.avatar,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? icon;
  final String? avatar;

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
              if (avatar != null)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.zoviOrange, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset(avatar!, fit: BoxFit.cover),
                  ),
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
