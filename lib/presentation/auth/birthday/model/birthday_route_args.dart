import 'package:zovi/presentation/auth/model/signup_flow.dart';
import 'package:flutter/foundation.dart';

@immutable
final class BirthdayRouteArgs {
  const BirthdayRouteArgs({required this.signupFlow});

  final SignupFlow signupFlow;

  int get stepCount => signupFlow.stepCount;

  int get activeStepIndex => switch (signupFlow) {
        SignupFlow.phone => 3,
        SignupFlow.social => 2,
      };
}
