import 'package:zovi/presentation/auth/model/signup_flow.dart';
import 'package:flutter/foundation.dart';

@immutable
final class CreateProfileRouteArgs {
  const CreateProfileRouteArgs({required this.signupFlow});

  final SignupFlow signupFlow;

  int get stepCount => signupFlow.stepCount;

  int get activeStepIndex => switch (signupFlow) {
        SignupFlow.phone => 2,
        SignupFlow.social => 1,
      };
}
