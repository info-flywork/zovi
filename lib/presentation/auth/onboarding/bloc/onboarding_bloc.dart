import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/utils/phone/phone_format.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/domain/auth/models/auth_session.dart';
import 'package:zovi/domain/auth/phone_auth_error.dart';
import 'package:zovi/presentation/auth/onboarding/bloc/onboarding_event.dart';
import 'package:zovi/presentation/auth/onboarding/bloc/onboarding_state.dart';

final class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc(this._authRepository) : super(const OnboardingInitial()) {
    on<OnboardingPhoneChanged>(_onPhoneChanged);
    on<OnboardingCountryChanged>(_onCountryChanged);
    on<OnboardingSendCodeTapped>(_onSendCode);
  }

  final AuthRepository _authRepository;

  Future<AuthSession> signInWithGoogle() => _authRepository.signInWithGoogle();

  Future<AuthSession> signInWithApple() => _authRepository.signInWithApple();

  void _onPhoneChanged(
    OnboardingPhoneChanged event,
    Emitter<OnboardingState> emit,
  ) {
    final format = PhoneFormats.forCountry(state.selectedCountry.isoCode);
    emit(
      OnboardingInitial(
        phone: format.limitDigits(event.phone),
        selectedCountry: state.selectedCountry,
      ),
    );
  }

  void _onCountryChanged(
    OnboardingCountryChanged event,
    Emitter<OnboardingState> emit,
  ) {
    final format = PhoneFormats.forCountry(event.country.isoCode);
    emit(
      OnboardingInitial(
        phone: format.limitDigits(state.phone),
        selectedCountry: event.country,
      ),
    );
  }

  Future<void> _onSendCode(
    OnboardingSendCodeTapped event,
    Emitter<OnboardingState> emit,
  ) async {
    final phone = state.phone.trim();
    if (phone.isEmpty) {
      emit(
        OnboardingError(
          message: 'error_enter_phone'.tr(),
          phone: phone,
          selectedCountry: state.selectedCountry,
        ),
      );
      return;
    }
    emit(
      OnboardingLoading(
        phone: phone,
        selectedCountry: state.selectedCountry,
      ),
    );
    try {
      await _authRepository.sendVerificationCode(
        phone: phone,
        dialCode: state.selectedCountry.dialCode,
      );
      emit(
        OnboardingSuccess(
          navigateTo: RoutePaths.otp.path,
          phone: phone,
          selectedCountry: state.selectedCountry,
        ),
      );
    } catch (error) {
      emit(
        OnboardingError(
          message: mapPhoneAuthError(error),
          phone: phone,
          selectedCountry: state.selectedCountry,
        ),
      );
    }
  }
}
