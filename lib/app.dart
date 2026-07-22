import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:zovi/core/router/app_router.dart';
import 'package:zovi/core/theme/app_theme.dart';
import 'package:zovi/core/utils/constants/string_constants.dart';

class ZoviApp extends StatelessWidget {
  const ZoviApp({super.key});

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
