import 'package:equatable/equatable.dart';
import 'package:zovi/core/models/country.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class OtpState extends Equatable {
  const OtpState({
    required this.phone,
    required this.selectedCountry,
    this.code = '',
    this.resendSeconds = 28,
  });

  final String phone;
  final Country selectedCountry;
  final String code;
  final int resendSeconds;

  bool get canResend => resendSeconds <= 0;
  bool get isCodeComplete => code.length == 6;

  @override
  List<Object?> get props => [phone, selectedCountry, code, resendSeconds];
}

@immutable
final class OtpInitial extends OtpState {
  const OtpInitial({
    required super.phone,
    required super.selectedCountry,
    super.code,
    super.resendSeconds,
  });
}

@immutable
final class OtpLoading extends OtpState {
  const OtpLoading({
    required super.phone,
    required super.selectedCountry,
    super.code,
    super.resendSeconds,
  });
}

@immutable
final class OtpResending extends OtpState {
  const OtpResending({
    required super.phone,
    required super.selectedCountry,
    super.code,
    super.resendSeconds,
  });
}

@immutable
final class OtpSuccess extends OtpState {
  const OtpSuccess({
    required this.navigateTo,
    required super.phone,
    required super.selectedCountry,
    this.navigateExtra,
    super.code,
    super.resendSeconds,
  });

  final String navigateTo;
  final Object? navigateExtra;

  @override
  List<Object?> get props => [
        phone,
        selectedCountry,
        code,
        resendSeconds,
        navigateTo,
        navigateExtra,
      ];
}

@immutable
final class OtpError extends OtpState {
  const OtpError({
    required this.message,
    required super.phone,
    required super.selectedCountry,
    super.code,
    super.resendSeconds,
  });

  final String message;

  @override
  List<Object?> get props => [phone, selectedCountry, code, resendSeconds, message];
}
