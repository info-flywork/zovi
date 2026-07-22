import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_button.dart';
import 'package:zovi/presentation/auth/notification_permission/bloc/notification_permission_bloc.dart';
import 'package:zovi/presentation/auth/notification_permission/bloc/notification_permission_event.dart';
import 'package:zovi/presentation/auth/notification_permission/bloc/notification_permission_state.dart';

class NotificationPermissionView extends StatelessWidget {
  const NotificationPermissionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: BlocConsumer<
              NotificationPermissionBloc,
              NotificationPermissionState
            >(
              listener: (context, state) {
                if (state is NotificationPermissionSuccess) {
                  context.go(state.navigateTo);
                }
              },
              builder: (context, state) {
                final isLoading = state is NotificationPermissionLoading;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'notification_title'.tr(),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w500,
                        height: 48 / 36,
                        letterSpacing: -0.72,
                        color: AppColors.deepRoast,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'notification_subtitle'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 20 / 16,
                        letterSpacing: -0.32,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Image.asset(
                      AssetPaths.notification,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                    const Spacer(),
                    AppButton(
                      label: isLoading ? 'loading'.tr() : 'continue'.tr(),
                      onPressed: isLoading
                          ? null
                          : () {
                              context.read<NotificationPermissionBloc>().add(
                                const NotificationPermissionContinueTapped(),
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
