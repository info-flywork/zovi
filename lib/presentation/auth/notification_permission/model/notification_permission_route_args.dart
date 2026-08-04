import 'package:zovi/presentation/auth/model/signup_flow.dart';
import 'package:flutter/foundation.dart';

@immutable
final class NotificationPermissionRouteArgs {
  const NotificationPermissionRouteArgs({required this.signupFlow});

  final SignupFlow signupFlow;
}
