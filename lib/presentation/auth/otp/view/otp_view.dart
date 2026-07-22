import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/snackbar/app_snackbar.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/phone/phone_format.dart';
import 'package:zovi/core/widgets/app_button.dart';
import 'package:zovi/core/widgets/otp_code_field.dart';
import 'package:zovi/presentation/auth/otp/bloc/otp_bloc.dart';
import 'package:zovi/presentation/auth/otp/bloc/otp_event.dart';
import 'package:zovi/presentation/auth/otp/bloc/otp_state.dart';
import 'package:zovi/presentation/auth/widgets/auth_progress_bar.dart';

part 'mixin/otp_view_mixin.dart';
part 'widgets/otp_loaded_body.dart';

class OtpView extends StatefulWidget {
  const OtpView({super.key});

  @override
  State<OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<OtpView> with OtpViewMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: BlocConsumer<OtpBloc, OtpState>(
          listener: (context, state) {
            if (state is OtpError) {
              showErrorSnackbar(state.message);
            } else if (state is OtpSuccess) {
              context.go(state.navigateTo);
            }
          },
          builder: (context, state) {
            return OtpLoadedBody(
              formattedPhone: formattedPhone(state),
              code: state.code,
              resendSeconds: state.resendSeconds,
              canResend: state.canResend,
              isLoading: state is OtpLoading,
              isResending: state is OtpResending,
              onCodeChanged: onCodeChanged,
              onVerify: onVerify,
              onResend: onResend,
            );
          },
        ),
      ),
    );
  }
}
