import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/presentation/auth/create_profile/model/create_profile_route_args.dart';
import 'package:zovi/presentation/auth/model/signup_flow.dart';
import 'package:zovi/presentation/auth/birthday/model/birthday_route_args.dart';
import 'package:flutter/foundation.dart';

@immutable
final class AuthSession {
  const AuthSession({
    required this.nextStep,
    required this.isProfileComplete,
    required this.onboardingDone,
    this.created = false,
    this.primaryAuth = '',
    this.userId = '',
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    final onboarding = json['onboarding'];
    final user = json['user'];
    final profileMap = profile is Map<String, dynamic> ? profile : null;
    final onboardingMap = onboarding is Map<String, dynamic> ? onboarding : null;
    final userMap = user is Map<String, dynamic> ? user : null;

    return AuthSession(
      nextStep: (json['nextStep'] as String?) ?? 'create_profile',
      created: json['created'] == true,
      isProfileComplete: profileMap?['isProfileComplete'] == true,
      onboardingDone: onboardingMap?['onboardingDone'] == true,
      primaryAuth: (userMap?['primaryAuth'] as String?)?.trim() ?? '',
      userId: (userMap?['id'] as String?)?.trim() ?? '',
    );
  }

  final String nextStep;
  final bool created;
  final bool isProfileComplete;
  final bool onboardingDone;
  final String primaryAuth;
  final String userId;

  SignupFlow get signupFlow =>
      primaryAuth == 'phone' ? SignupFlow.phone : SignupFlow.social;

  /// Path + optional extra for go_router.
  ({String path, Object? extra}) get destination {
    switch (nextStep) {
      case 'home':
        return (path: RoutePaths.home.path, extra: null);
      case 'birthday':
        return (
          path: RoutePaths.birthday.path,
          extra: BirthdayRouteArgs(signupFlow: signupFlow),
        );
      case 'create_profile':
      default:
        return (
          path: RoutePaths.createProfile.path,
          extra: CreateProfileRouteArgs(signupFlow: signupFlow),
        );
    }
  }

  /// New phone accounts see the "stamp earned" celebration once.
  /// Returning users skip it and go straight to their next step.
  ({String path, Object? extra}) get phoneOtpDestination {
    if (created && primaryAuth == 'phone') {
      return (path: RoutePaths.phoneVerified.path, extra: null);
    }
    return destination;
  }
}
