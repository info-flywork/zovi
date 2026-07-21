import 'package:equatable/equatable.dart';
import 'package:zovi/presentation/auth/model/signup_flow.dart';

sealed class CreateProfileState extends Equatable {
  const CreateProfileState({
    required this.signupFlow,
    this.fullName = '',
    this.username = '',
  });

  final SignupFlow signupFlow;
  final String fullName;
  final String username;

  bool get isFormComplete =>
      fullName.trim().isNotEmpty && username.trim().isNotEmpty;

  int get stepCount => signupFlow.stepCount;

  int get activeStepIndex => switch (signupFlow) {
        SignupFlow.phone => 2,
        SignupFlow.social => 1,
      };

  @override
  List<Object?> get props => [signupFlow, fullName, username];
}

final class CreateProfileInitial extends CreateProfileState {
  const CreateProfileInitial({
    required super.signupFlow,
    super.fullName,
    super.username,
  });
}

final class CreateProfileLoading extends CreateProfileState {
  const CreateProfileLoading({
    required super.signupFlow,
    super.fullName,
    super.username,
  });
}

final class CreateProfileSuccess extends CreateProfileState {
  const CreateProfileSuccess({
    required this.navigateTo,
    required super.signupFlow,
    super.fullName,
    super.username,
  });

  final String navigateTo;

  @override
  List<Object?> get props => [signupFlow, fullName, username, navigateTo];
}

final class CreateProfileError extends CreateProfileState {
  const CreateProfileError({
    required this.message,
    required super.signupFlow,
    super.fullName,
    super.username,
  });

  final String message;

  @override
  List<Object?> get props => [signupFlow, fullName, username, message];
}
