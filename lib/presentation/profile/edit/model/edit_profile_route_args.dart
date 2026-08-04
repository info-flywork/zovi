import 'package:zovi/domain/user/user_repository.dart';
import 'package:flutter/foundation.dart';

@immutable
final class EditProfileRouteArgs {
  const EditProfileRouteArgs({required this.user});

  final UserProfile user;
}
