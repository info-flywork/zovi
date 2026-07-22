import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_button.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/presentation/auth/birthday/bloc/birthday_bloc.dart';
import 'package:zovi/presentation/auth/birthday/bloc/birthday_event.dart';
import 'package:zovi/presentation/auth/birthday/bloc/birthday_state.dart';
import 'package:zovi/presentation/auth/model/signup_flow.dart';
import 'package:zovi/presentation/auth/notification_permission/model/notification_permission_route_args.dart';
import 'package:zovi/presentation/auth/widgets/auth_progress_bar.dart';

part 'mixin/birthday_view_mixin.dart';
part 'widgets/birthday_date_picker.dart';
part 'widgets/birthday_loaded_body.dart';

class BirthdayView extends StatefulWidget {
  const BirthdayView({required this.signupFlow, super.key});

  final SignupFlow signupFlow;

  @override
  State<BirthdayView> createState() => _BirthdayViewState();
}

class _BirthdayViewState extends State<BirthdayView> with BirthdayViewMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: BlocConsumer<BirthdayBloc, BirthdayState>(
          listener: (context, state) {
            if (state is BirthdaySuccess) {
              context.go(
                state.navigateTo,
                extra: NotificationPermissionRouteArgs(
                  signupFlow: state.signupFlow,
                ),
              );
            }
          },
          builder: (context, state) {
            return BirthdayLoadedBody(
              birthDate: state.birthDate,
              stepCount: state.stepCount,
              activeStepIndex: state.activeStepIndex,
              isLoading: state is BirthdayLoading,
              onDateChanged: onDateChanged,
              onContinue: onContinue,
            );
          },
        ),
      ),
    );
  }
}

const _monthKeys = [
  'month_january',
  'month_february',
  'month_march',
  'month_april',
  'month_may',
  'month_june',
  'month_july',
  'month_august',
  'month_september',
  'month_october',
  'month_november',
  'month_december',
];

String formatBirthDate(DateTime date) {
  return '${date.day} ${_monthKeys[date.month - 1].tr()} ${date.year}';
}
