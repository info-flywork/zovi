import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/snackbar/app_snackbar.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_button.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/presentation/auth/birthday/model/birthday_route_args.dart';
import 'package:zovi/presentation/auth/model/signup_flow.dart';
import 'package:zovi/presentation/auth/create_profile/bloc/create_profile_bloc.dart';
import 'package:zovi/presentation/auth/create_profile/bloc/create_profile_event.dart';
import 'package:zovi/presentation/auth/create_profile/bloc/create_profile_state.dart';
import 'package:zovi/presentation/auth/widgets/auth_progress_bar.dart';

part 'mixin/create_profile_view_mixin.dart';
part 'widgets/create_profile_loaded_body.dart';
part 'widgets/profile_text_field.dart';

class CreateProfileView extends StatefulWidget {
  const CreateProfileView({required this.signupFlow, super.key});

  final SignupFlow signupFlow;

  @override
  State<CreateProfileView> createState() => _CreateProfileViewState();
}

class _CreateProfileViewState extends State<CreateProfileView>
    with CreateProfileViewMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: BlocConsumer<CreateProfileBloc, CreateProfileState>(
          listener: (context, state) {
            if (state is CreateProfileError) {
              showErrorSnackbar(state.message);
            } else if (state is CreateProfileSuccess) {
              context.go(
                state.navigateTo,
                extra: BirthdayRouteArgs(signupFlow: state.signupFlow),
              );
            }
          },
          builder: (context, state) {
            return CreateProfileLoadedBody(
              fullName: state.fullName,
              username: state.username,
              stepCount: state.stepCount,
              activeStepIndex: state.activeStepIndex,
              isLoading: state is CreateProfileLoading,
              onFullNameChanged: onFullNameChanged,
              onUsernameChanged: onUsernameChanged,
              onContinue: onContinue,
            );
          },
        ),
      ),
    );
  }
}
