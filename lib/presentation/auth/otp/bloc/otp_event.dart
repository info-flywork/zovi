import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class OtpEvent extends Equatable {
  const OtpEvent();

  @override
  List<Object?> get props => [];
}

@immutable
final class OtpCodeChanged extends OtpEvent {
  const OtpCodeChanged(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

@immutable
final class OtpVerifyTapped extends OtpEvent {
  const OtpVerifyTapped();
}

@immutable
final class OtpResendTapped extends OtpEvent {
  const OtpResendTapped();
}

@immutable
final class OtpResendTick extends OtpEvent {
  const OtpResendTick();
}
