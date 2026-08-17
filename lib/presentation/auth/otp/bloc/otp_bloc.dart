import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zovi/core/models/country.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/domain/auth/phone_auth_error.dart';
import 'package:zovi/presentation/auth/otp/bloc/otp_event.dart';
import 'package:zovi/presentation/auth/otp/bloc/otp_state.dart';

final class OtpBloc extends Bloc<OtpEvent, OtpState> {
  OtpBloc(
    this._authRepository, {
    required String phone,
    required Country selectedCountry,
  }) : super(
          OtpInitial(
            phone: phone,
            selectedCountry: selectedCountry,
          ),
        ) {
    on<OtpCodeChanged>(_onCodeChanged);
    on<OtpVerifyTapped>(_onVerify);
    on<OtpResendTapped>(_onResend);
    on<OtpResendTick>(_onResendTick);
    _startResendTimer();
  }

  final AuthRepository _authRepository;
  Timer? _resendTimer;

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isClosed) return;
      add(const OtpResendTick());
    });
  }

  void _onCodeChanged(OtpCodeChanged event, Emitter<OtpState> emit) {
    final digits = event.code.replaceAll(RegExp(r'\D'), '');
    final code = digits.length <= 6 ? digits : digits.substring(0, 6);
    emit(
      OtpInitial(
        phone: state.phone,
        selectedCountry: state.selectedCountry,
        code: code,
        resendSeconds: state.resendSeconds,
      ),
    );
  }

  Future<void> _onVerify(OtpVerifyTapped event, Emitter<OtpState> emit) async {
    if (!state.isCodeComplete) {
      emit(
        OtpError(
          message: 'error_enter_otp'.tr(),
          phone: state.phone,
          selectedCountry: state.selectedCountry,
          code: state.code,
          resendSeconds: state.resendSeconds,
        ),
      );
      return;
    }

    emit(
      OtpLoading(
        phone: state.phone,
        selectedCountry: state.selectedCountry,
        code: state.code,
        resendSeconds: state.resendSeconds,
      ),
    );

    try {
      final session = await _authRepository.verifyCode(
        state.phone,
        state.code,
      );
      final dest = session.phoneOtpDestination;

      emit(
        OtpSuccess(
          navigateTo: dest.path,
          navigateExtra: dest.extra,
          phone: state.phone,
          selectedCountry: state.selectedCountry,
          code: state.code,
          resendSeconds: state.resendSeconds,
        ),
      );
    } on FirebaseAuthException catch (error) {
      final invalidCode = error.code == 'invalid-verification-code' ||
          error.code == 'invalid-verification-id' ||
          error.code == 'session-expired';
      emit(
        OtpError(
          message: invalidCode
              ? 'error_invalid_otp'.tr()
              : mapPhoneAuthError(error),
          phone: state.phone,
          selectedCountry: state.selectedCountry,
          code: state.code,
          resendSeconds: state.resendSeconds,
        ),
      );
    } catch (_) {
      emit(
        OtpError(
          message: 'error_login_failed'.tr(),
          phone: state.phone,
          selectedCountry: state.selectedCountry,
          code: state.code,
          resendSeconds: state.resendSeconds,
        ),
      );
    }
  }

  Future<void> _onResend(OtpResendTapped event, Emitter<OtpState> emit) async {
    if (!state.canResend) return;

    emit(
      OtpResending(
        phone: state.phone,
        selectedCountry: state.selectedCountry,
        code: state.code,
        resendSeconds: state.resendSeconds,
      ),
    );

    try {
      await _authRepository.sendVerificationCode(
        phone: state.phone,
        dialCode: state.selectedCountry.dialCode,
      );
      emit(
        OtpInitial(
          phone: state.phone,
          selectedCountry: state.selectedCountry,
          code: state.code,
          resendSeconds: 28,
        ),
      );
      _startResendTimer();
    } catch (error) {
      emit(
        OtpError(
          message: mapPhoneAuthError(error),
          phone: state.phone,
          selectedCountry: state.selectedCountry,
          code: state.code,
          resendSeconds: state.resendSeconds,
        ),
      );
    }
  }

  void _onResendTick(OtpResendTick event, Emitter<OtpState> emit) {
    if (state is! OtpInitial) return;
    if (state.resendSeconds <= 0) return;

    emit(
      OtpInitial(
        phone: state.phone,
        selectedCountry: state.selectedCountry,
        code: state.code,
        resendSeconds: state.resendSeconds - 1,
      ),
    );
  }

  @override
  Future<void> close() {
    _resendTimer?.cancel();
    return super.close();
  }
}
