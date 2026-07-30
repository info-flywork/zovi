import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/snackbar/app_snackbar.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/profile/user_profile/model/user_profile_route_args.dart';
import 'package:zovi/presentation/profile/user_profile/view/user_profile_view.dart';

/// Deep link / share entry: shows profile shell immediately, hydrates in view.
class PublicProfileLoaderView extends StatefulWidget {
  const PublicProfileLoaderView({required this.username, super.key});

  final String username;

  @override
  State<PublicProfileLoaderView> createState() =>
      _PublicProfileLoaderViewState();
}

class _PublicProfileLoaderViewState extends State<PublicProfileLoaderView> {
  late final String _handle = widget.username.startsWith('@')
      ? widget.username.substring(1).trim()
      : widget.username.trim();

  PublicUserProfile? _seed;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    if (_handle.isEmpty) {
      _failAndPop();
      return;
    }

    final me = getIt<UserRepository>().cachedCurrentUser;
    if (me != null &&
        me.usernameHandle.toLowerCase() == _handle.toLowerCase()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go(RoutePaths.profile.path);
      });
      return;
    }

    final peeked = getIt<UserRepository>().peekPublicUserProfile(_handle);
    _seed = peeked ?? PublicUserProfile.skeleton(username: _handle);
  }

  void _failAndPop() {
    if (!mounted) return;
    setState(() => _failed = true);
    AppSnackbar.instance.show(
      context,
      'profile_not_found'.tr(),
      isError: true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(RoutePaths.home.path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFFFFF),
        body: SizedBox.shrink(),
      );
    }
    final seed = _seed;
    if (seed == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFFFFF),
        body: SizedBox.shrink(),
      );
    }
    return UserProfileView(args: UserProfileRouteArgs(user: seed));
  }
}
