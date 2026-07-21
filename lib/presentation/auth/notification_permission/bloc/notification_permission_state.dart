import 'package:equatable/equatable.dart';
import 'package:zovi/presentation/auth/model/signup_flow.dart';

sealed class NotificationPermissionState extends Equatable {
  const NotificationPermissionState({required this.signupFlow});

  final SignupFlow signupFlow;

  @override
  List<Object?> get props => [signupFlow];
}

final class NotificationPermissionInitial extends NotificationPermissionState {
  const NotificationPermissionInitial({required super.signupFlow});
}

final class NotificationPermissionLoading extends NotificationPermissionState {
  const NotificationPermissionLoading({required super.signupFlow});
}

final class NotificationPermissionSuccess extends NotificationPermissionState {
  const NotificationPermissionSuccess({
    required this.navigateTo,
    required super.signupFlow,
  });

  final String navigateTo;

  @override
  List<Object?> get props => [signupFlow, navigateTo];
}
