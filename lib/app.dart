import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/router/app_router.dart';
import 'package:zovi/core/theme/app_theme.dart';
import 'package:zovi/core/utils/constants/string_constants.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/domain/user/user_repository.dart';

class ZoviApp extends StatefulWidget {
  const ZoviApp({super.key});

  @override
  State<ZoviApp> createState() => _ZoviAppState();
}

class _ZoviAppState extends State<ZoviApp> with WidgetsBindingObserver {
  static const _authRoutes = {
    '/',
    '/intro',
    '/onboarding',
    '/otp',
    '/phone-verified',
    '/create-profile',
    '/birthday',
    '/notification-permission',
    '/location-permission',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _renewSessionOnResume();
    }
  }

  Future<void> _renewSessionOnResume() async {
    final path = AppRouter.router.state.uri.path;
    if (_authRoutes.contains(path)) return;

    final stillValid = await getIt<AuthRepository>().renewSessionOnResume();
    if (stillValid) return;

    getIt<UserRepository>().clearSessionCache();
    await resetUserScopedSingletons();
    AppRouter.router.go(RoutePaths.onboarding.path);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: StringConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}
