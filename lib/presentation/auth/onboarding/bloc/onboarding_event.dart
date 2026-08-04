import 'package:equatable/equatable.dart';
import 'package:zovi/core/models/country.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

@immutable
final class OnboardingPhoneChanged extends OnboardingEvent {
  const OnboardingPhoneChanged(this.phone);

  final String phone;

  @override
  List<Object?> get props => [phone];
}

@immutable
final class OnboardingSendCodeTapped extends OnboardingEvent {
  const OnboardingSendCodeTapped();
}

@immutable
final class OnboardingCountryChanged extends OnboardingEvent {
  const OnboardingCountryChanged(this.country);

  final Country country;

  @override
  List<Object?> get props => [country];
}
