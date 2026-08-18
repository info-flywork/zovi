import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_button.dart';
import 'package:zovi/presentation/auth/location_permission/bloc/location_permission_bloc.dart';
import 'package:zovi/presentation/auth/location_permission/bloc/location_permission_event.dart';
import 'package:zovi/presentation/auth/location_permission/bloc/location_permission_state.dart';

@immutable
final class LocationPermissionView extends StatelessWidget {
  const LocationPermissionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: BlocConsumer<LocationPermissionBloc, LocationPermissionState>(
            listener: (context, state) {
              if (state is LocationPermissionSuccess) {
                context.go(state.navigateTo);
              }
            },
            builder: (context, state) {
              final isLoading = state is LocationPermissionLoading;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'location_title'.tr(),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w500,
                      height: 40 / 36,
                      letterSpacing: -0.72,
                      color: AppColors.deepRoast,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _FeatureRow(
                    iconPath: AssetPaths.iconTickPink,
                    text: 'location_bullet_check_in'.tr(),
                  ),
                  const SizedBox(height: 18),
                  _FeatureRow(
                    iconPath: AssetPaths.iconBell,
                    text: 'location_bullet_reminders'.tr(),
                  ),
                  const SizedBox(height: 18),
                  _FeatureRow(
                    iconPath: AssetPaths.iconVisits,
                    text: 'location_bullet_map'.tr(),
                  ),
                  const SizedBox(height: 18),
                  _FeatureRow(
                    iconPath: AssetPaths.iconStars,
                    text: 'location_bullet_discover'.tr(),
                  ),
                  const SizedBox(height: 26),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _MapFirstPreview()),
                      SizedBox(width: 28),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: _MapSecondPreview(),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  AppButton(
                    label: isLoading ? 'loading'.tr() : 'get_started'.tr(),
                    onPressed: isLoading
                        ? null
                        : () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            context.read<LocationPermissionBloc>().add(
                              const LocationPermissionContinueTapped(),
                            );
                          },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

@immutable
final class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.iconPath, required this.text});

  final String iconPath;
  final String text;

  static const double _iconSlotWidth = 24;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _iconSlotWidth,
          child: Center(
            child: SvgPicture.asset(iconPath, width: 20, height: 20),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 20 / 16,
              letterSpacing: -0.32,
              color: AppColors.black,
            ),
          ),
        ),
      ],
    );
  }
}

@immutable
final class _MapFirstPreview extends StatelessWidget {
  const _MapFirstPreview();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 167 / 190,
            child: Image.asset(AssetPaths.mapFirst, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          right: -10,
          bottom: -10,
          child: Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: AppColors.deepRoast,
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(AssetPaths.iconShare, fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }
}

@immutable
final class _MapSecondPreview extends StatelessWidget {
  const _MapSecondPreview();

  static const _mapLabelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    height: 16 / 12,
    letterSpacing: -0.24,
    color: AppColors.zoviOrange,
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 167 / 190,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(AssetPaths.mapSecond, fit: BoxFit.cover),
            Align(
              alignment: const Alignment(0, 0.08),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipOval(
                    child: Image.asset(
                      AssetPaths.mapSecondAvatar,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Beyoglu, Istanbul',
                    textAlign: TextAlign.center,
                    style: _mapLabelStyle,
                  ),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: _mapLabelStyle,
                      children: [
                        const TextSpan(
                          text: 'Samantha',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 16 / 10,
                            letterSpacing: -0.2,
                          ),
                        ),
                        TextSpan(text: ' ${'location_demo_checked_in'.tr()}'),
                      ],
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
