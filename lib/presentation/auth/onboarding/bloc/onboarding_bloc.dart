import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/utils/phone/phone_format.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/presentation/auth/onboarding/bloc/onboarding_event.dart';
import 'package:zovi/presentation/auth/onboarding/bloc/onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc(this._authRepository) : super(const OnboardingInitial()) {
    on<OnboardingPhoneChanged>(_onPhoneChanged);
    on<OnboardingCountryChanged>(_onCountryChanged);
    on<OnboardingSendCodeTapped>(_onSendCode);
    on<OnboardingGoogleTapped>(_onSocial);
    on<OnboardingAppleTapped>(_onSocial);
  }

  final AuthRepository _authRepository;

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
          message: 'Telefon numarası gir.',
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
    await _authRepository.sendVerificationCode(phone);
    emit(
      OnboardingSuccess(
        navigateTo: RoutePaths.otp.path,
        phone: phone,
        selectedCountry: state.selectedCountry,
      ),
    );
  }

  Future<void> _onSocial(
    OnboardingEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(
      OnboardingLoading(
        phone: state.phone,
        selectedCountry: state.selectedCountry,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 600));
    emit(
      OnboardingSuccess(
        navigateTo: RoutePaths.createProfile.path,
        phone: state.phone,
        selectedCountry: state.selectedCountry,
      ),
    );
  }
}
