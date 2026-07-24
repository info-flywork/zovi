import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/profile/user_profile/model/user_profile_route_args.dart';

Future<void> openUserProfile(
  BuildContext context,
  String usernameOrName,
) async {
  final value = usernameOrName.trim();
  if (value.isEmpty) return;
  if (value.toLowerCase() == 'you') return;

  final profile = await getIt<UserRepository>().getPublicUserProfile(value);
  if (!context.mounted) return;

  context.push(
    RoutePaths.userProfile.path,
    extra: UserProfileRouteArgs(user: profile),
  );
}
