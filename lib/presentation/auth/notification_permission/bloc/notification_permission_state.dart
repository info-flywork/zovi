import 'package:equatable/equatable.dart';
import 'package:zovi/presentation/auth/model/signup_flow.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class NotificationPermissionState extends Equatable {
  const NotificationPermissionState({required this.signupFlow});

  final SignupFlow signupFlow;

  @override
  List<Object?> get props => [signupFlow];
}

@immutable
final class NotificationPermissionInitial extends NotificationPermissionState {
  const NotificationPermissionInitial({required super.signupFlow});
}

@immutable
final class NotificationPermissionLoading extends NotificationPermissionState {
  const NotificationPermissionLoading({required super.signupFlow});
}

@immutable
final class NotificationPermissionSuccess extends NotificationPermissionState {
  const NotificationPermissionSuccess({
    required this.navigateTo,
    required super.signupFlow,
  });

  final String navigateTo;

  @override
  List<Object?> get props => [signupFlow, navigateTo];
}
