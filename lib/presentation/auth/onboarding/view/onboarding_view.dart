import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zovi/core/data/countries.dart';
import 'package:zovi/core/models/country.dart';
import 'package:zovi/core/snackbar/app_snackbar.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/constants/string_constants.dart';
import 'package:zovi/core/utils/phone/country_phone_input_formatter.dart';
import 'package:zovi/core/utils/phone/phone_format.dart';
import 'package:zovi/core/widgets/app_button.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/presentation/auth/onboarding/bloc/onboarding_bloc.dart';
import 'package:zovi/presentation/auth/onboarding/bloc/onboarding_event.dart';
import 'package:zovi/presentation/auth/onboarding/bloc/onboarding_state.dart';
import 'package:zovi/presentation/auth/create_profile/model/create_profile_route_args.dart';
import 'package:zovi/presentation/auth/model/signup_flow.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/presentation/auth/otp/model/otp_route_args.dart';
import 'package:zovi/presentation/auth/widgets/auth_progress_bar.dart';

part 'mixin/onboarding_view_mixin.dart';
part 'widgets/onboarding_loaded_body.dart';
part 'widgets/onboarding_phone_field.dart';
part 'widgets/social_login_button.dart';
part 'widgets/country_picker_sheet.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView>
    with OnboardingViewMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: BlocConsumer<OnboardingBloc, OnboardingState>(
          listener: (context, state) {
            if (state is OnboardingError) {
              showErrorSnackbar(state.message);
            } else if (state is OnboardingSuccess) {
              if (state.navigateTo == RoutePaths.otp.path) {
                context.go(
                  state.navigateTo,
                  extra: OtpRouteArgs(
                    phone: state.phone,
                    selectedCountry: state.selectedCountry,
                  ),
                );
              } else if (state.navigateTo == RoutePaths.createProfile.path) {
                context.go(
                  state.navigateTo,
                  extra: const CreateProfileRouteArgs(
                    signupFlow: SignupFlow.social,
                  ),
                );
              } else {
                context.go(state.navigateTo);
              }
            }
          },
          builder: (context, state) {
            return OnboardingLoadedBody(
              phone: state.phone,
              selectedCountry: state.selectedCountry,
              isLoading: state is OnboardingLoading,
              onPhoneChanged: onPhoneChanged,
              onCountryTap: onCountryTap,
              onSendCode: onSendCode,
              onGoogle: onGoogle,
              onApple: onApple,
            );
          },
        ),
      ),
    );
  }
}
