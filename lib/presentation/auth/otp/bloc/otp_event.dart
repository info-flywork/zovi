import 'package:equatable/equatable.dart';

sealed class OtpEvent extends Equatable {
  const OtpEvent();

  @override
  List<Object?> get props => [];
}

final class OtpCodeChanged extends OtpEvent {
  const OtpCodeChanged(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

final class OtpVerifyTapped extends OtpEvent {
  const OtpVerifyTapped();
}

final class OtpResendTapped extends OtpEvent {
  const OtpResendTapped();
}

final class OtpResendTick extends OtpEvent {
  const OtpResendTick();
}
