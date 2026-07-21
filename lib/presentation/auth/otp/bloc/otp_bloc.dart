import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zovi/core/models/country.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/presentation/auth/otp/bloc/otp_event.dart';
import 'package:zovi/presentation/auth/otp/bloc/otp_state.dart';

class OtpBloc extends Bloc<OtpEvent, OtpState> {
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
          message: '6 haneli kodu gir.',
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

    final verified = await _authRepository.verifyCode(
      state.phone,
      state.code,
    );

    if (!verified) {
      emit(
        OtpError(
          message: 'Doğrulama kodu hatalı.',
          phone: state.phone,
          selectedCountry: state.selectedCountry,
          code: state.code,
          resendSeconds: state.resendSeconds,
        ),
      );
      return;
    }

    emit(
      OtpSuccess(
        navigateTo: RoutePaths.phoneVerified.path,
        phone: state.phone,
        selectedCountry: state.selectedCountry,
        code: state.code,
        resendSeconds: state.resendSeconds,
      ),
    );
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

    await _authRepository.sendVerificationCode(state.phone);

    emit(
      OtpInitial(
        phone: state.phone,
        selectedCountry: state.selectedCountry,
        code: state.code,
        resendSeconds: 28,
      ),
    );
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
