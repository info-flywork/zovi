import 'package:equatable/equatable.dart';
import 'package:zovi/presentation/auth/model/signup_flow.dart';
import 'package:flutter/foundation.dart';

enum UsernameAvailabilityStatus {
  idle,
  checking,
  available,
  taken,
  invalid,
}

@immutable
sealed class CreateProfileState extends Equatable {
  const CreateProfileState({
    required this.signupFlow,
    this.fullName = '',
    this.username = '',
    this.usernameStatus = UsernameAvailabilityStatus.idle,
    this.usernameSuggestions = const [],
  });

  final SignupFlow signupFlow;
  final String fullName;
  final String username;
  final UsernameAvailabilityStatus usernameStatus;
  final List<String> usernameSuggestions;

  bool get isFormComplete =>
      fullName.trim().isNotEmpty && username.trim().isNotEmpty;

  bool get canContinue =>
      isFormComplete &&
      usernameStatus == UsernameAvailabilityStatus.available;

  int get stepCount => signupFlow.stepCount;

  int get activeStepIndex => switch (signupFlow) {
        SignupFlow.phone => 2,
        SignupFlow.social => 1,
      };

  @override
  List<Object?> get props => [
        signupFlow,
        fullName,
        username,
        usernameStatus,
        usernameSuggestions,
      ];
}

@immutable
final class CreateProfileInitial extends CreateProfileState {
  const CreateProfileInitial({
    required super.signupFlow,
    super.fullName,
    super.username,
    super.usernameStatus,
    super.usernameSuggestions,
  });
}

@immutable
final class CreateProfileLoading extends CreateProfileState {
  const CreateProfileLoading({
    required super.signupFlow,
    super.fullName,
    super.username,
    super.usernameStatus,
    super.usernameSuggestions,
  });
}

@immutable
final class CreateProfileSuccess extends CreateProfileState {
  const CreateProfileSuccess({
    required this.navigateTo,
    required super.signupFlow,
    super.fullName,
    super.username,
    super.usernameStatus,
    super.usernameSuggestions,
  });

  final String navigateTo;

  @override
  List<Object?> get props => [
        ...super.props,
        navigateTo,
      ];
}

@immutable
final class CreateProfileError extends CreateProfileState {
  const CreateProfileError({
    required this.message,
    required super.signupFlow,
    super.fullName,
    super.username,
    super.usernameStatus,
    super.usernameSuggestions,
  });

  final String message;

  @override
  List<Object?> get props => [
        ...super.props,
        message,
      ];
}
