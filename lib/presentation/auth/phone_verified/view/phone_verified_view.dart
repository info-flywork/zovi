import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/app_button.dart';
import 'package:zovi/presentation/auth/create_profile/model/create_profile_route_args.dart';
import 'package:zovi/presentation/auth/model/signup_flow.dart';

part 'widgets/phone_verified_body.dart';

class PhoneVerifiedView extends StatelessWidget {
  const PhoneVerifiedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: PhoneVerifiedBody(
          onContinue: () => context.go(
            RoutePaths.createProfile.path,
            extra: const CreateProfileRouteArgs(signupFlow: SignupFlow.phone),
          ),
        ),
      ),
    );
  }
}
