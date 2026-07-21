import 'package:equatable/equatable.dart';
import 'package:zovi/core/models/country.dart';

sealed class OnboardingState extends Equatable {
  const OnboardingState({
    this.phone = '',
    this.selectedCountry = Country.turkey,
  });

  final String phone;
  final Country selectedCountry;

  @override
  List<Object?> get props => [phone, selectedCountry];
}

final class OnboardingInitial extends OnboardingState {
  const OnboardingInitial({super.phone, super.selectedCountry});
}

final class OnboardingLoading extends OnboardingState {
  const OnboardingLoading({super.phone, super.selectedCountry});
}

final class OnboardingSuccess extends OnboardingState {
  const OnboardingSuccess({
    required this.navigateTo,
    super.phone,
    super.selectedCountry,
  });

  final String navigateTo;

  @override
  List<Object?> get props => [phone, selectedCountry, navigateTo];
}

final class OnboardingError extends OnboardingState {
  const OnboardingError({
    required this.message,
    super.phone,
    super.selectedCountry,
  });

  final String message;

  @override
  List<Object?> get props => [phone, selectedCountry, message];
}
