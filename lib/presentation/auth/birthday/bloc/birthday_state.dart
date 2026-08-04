import 'package:equatable/equatable.dart';
import 'package:zovi/presentation/auth/model/signup_flow.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class BirthdayState extends Equatable {
  const BirthdayState({
    required this.signupFlow,
    required this.birthDate,
  });

  final SignupFlow signupFlow;
  final DateTime birthDate;

  int get stepCount => signupFlow.stepCount;

  int get activeStepIndex => switch (signupFlow) {
        SignupFlow.phone => 3,
        SignupFlow.social => 2,
      };

  @override
  List<Object?> get props => [signupFlow, birthDate];
}

@immutable
final class BirthdayInitial extends BirthdayState {
  const BirthdayInitial({
    required super.signupFlow,
    required super.birthDate,
  });
}

@immutable
final class BirthdayLoading extends BirthdayState {
  const BirthdayLoading({
    required super.signupFlow,
    required super.birthDate,
  });
}

@immutable
final class BirthdaySuccess extends BirthdayState {
  const BirthdaySuccess({
    required this.navigateTo,
    required super.signupFlow,
    required super.birthDate,
  });

  final String navigateTo;

  @override
  List<Object?> get props => [signupFlow, birthDate, navigateTo];
}

@immutable
final class BirthdayError extends BirthdayState {
  const BirthdayError({
    required this.message,
    required super.signupFlow,
    required super.birthDate,
  });

  final String message;

  @override
  List<Object?> get props => [signupFlow, birthDate, message];
}
