import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';

class AddPlanSuccessView extends StatelessWidget {
  const AddPlanSuccessView({
    this.friendAvatars = const [
      AssetPaths.avatarLyra,
      AssetPaths.avatarSona,
      AssetPaths.avatarJessica,
    ],
    this.friendsLabel = '5+ friends\nare joining',
    super.key,
  });

  final List<String> friendAvatars;
  final String friendsLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Image.asset(
                AssetPaths.greenTick,
                width: 210,
                height: 140,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              const Text(
                'Plan eklendi! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w500,
                  height: 40 / 36,
                  letterSpacing: -0.72,
                  color: AppColors.deepRoast,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Arkadaşların planını görebilir.\nYollar kesişirse seni haberdar\nedeceğiz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 20 / 16,
                  letterSpacing: -0.32,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _AvatarPile(avatars: friendAvatars),
                  const SizedBox(width: 8),
                  Text(
                    friendsLabel,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.15,
                      letterSpacing: -0.24,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: GestureDetector(
                  onTap: () => context.go(RoutePaths.profile.path),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.deepRoast,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Center(
                      child: Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          height: 1,
                          letterSpacing: -0.34,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarPile extends StatelessWidget {
  const _AvatarPile({required this.avatars});

  final List<String> avatars;

  @override
  Widget build(BuildContext context) {
    const size = 34.0;
    const overlap = 11.0;
    final shown = avatars.take(3).toList();
    final width = size + (shown.length - 1) * (size - overlap);

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 3),
                ),
                child: ClipOval(
                  child: Image.asset(shown[i], fit: BoxFit.cover),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
