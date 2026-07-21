enum SignupFlow {
  phone,
  social,
}

extension SignupFlowSteps on SignupFlow {
  int get stepCount => switch (this) {
        SignupFlow.phone => 4,
        SignupFlow.social => 3,
      };
}
