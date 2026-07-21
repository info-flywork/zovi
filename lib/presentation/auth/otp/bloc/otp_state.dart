import 'package:equatable/equatable.dart';
import 'package:zovi/core/models/country.dart';

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

final class OtpInitial extends OtpState {
  const OtpInitial({
    required super.phone,
    required super.selectedCountry,
    super.code,
    super.resendSeconds,
  });
}

final class OtpLoading extends OtpState {
  const OtpLoading({
    required super.phone,
    required super.selectedCountry,
    super.code,
    super.resendSeconds,
  });
}

final class OtpResending extends OtpState {
  const OtpResending({
    required super.phone,
    required super.selectedCountry,
    super.code,
    super.resendSeconds,
  });
}

final class OtpSuccess extends OtpState {
  const OtpSuccess({
    required this.navigateTo,
    required super.phone,
    required super.selectedCountry,
    super.code,
    super.resendSeconds,
  });

  final String navigateTo;

  @override
  List<Object?> get props => [phone, selectedCountry, code, resendSeconds, navigateTo];
}

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
