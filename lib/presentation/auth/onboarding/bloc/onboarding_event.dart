import 'package:equatable/equatable.dart';
import 'package:zovi/core/models/country.dart';

sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

final class OnboardingPhoneChanged extends OnboardingEvent {
  const OnboardingPhoneChanged(this.phone);

  final String phone;

  @override
  List<Object?> get props => [phone];
}

final class OnboardingSendCodeTapped extends OnboardingEvent {
  const OnboardingSendCodeTapped();
}

final class OnboardingGoogleTapped extends OnboardingEvent {
  const OnboardingGoogleTapped();
}

final class OnboardingAppleTapped extends OnboardingEvent {
  const OnboardingAppleTapped();
}

final class OnboardingCountryChanged extends OnboardingEvent {
  const OnboardingCountryChanged(this.country);

  final Country country;

  @override
  List<Object?> get props => [country];
}
