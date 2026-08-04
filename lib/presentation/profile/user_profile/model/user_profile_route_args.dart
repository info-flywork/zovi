import 'package:zovi/domain/user/user_repository.dart';
import 'package:flutter/foundation.dart';

@immutable
final class UserProfileRouteArgs {
  const UserProfileRouteArgs({required this.user});

  final PublicUserProfile user;
}
