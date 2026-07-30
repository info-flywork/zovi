import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';

class CreateStickerSuccessView extends StatelessWidget {
  const CreateStickerSuccessView({super.key});

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
              Text(
                'sticker_created_title'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w500,
                  height: 40 / 36,
                  letterSpacing: -0.72,
                  color: AppColors.deepRoast,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'sticker_created_subtitle'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 20 / 16,
                  letterSpacing: -0.32,
                  color: AppColors.deepRoast.withValues(alpha: 0.65),
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: GestureDetector(
                  onTap: () {
                    context.pop(true);
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.deepRoast,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Center(
                      child: Text(
                        'continue'.tr(),
                        style: const TextStyle(
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
