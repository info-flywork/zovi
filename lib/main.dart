import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zovi/app.dart';
import 'package:zovi/core/init/app_init.dart';
import 'package:zovi/core/locale/app_locale.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await EasyLocalization.ensureInitialized();
  await AppInit.init();
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('tr'),
        Locale('de'),
        Locale('fr'),
        Locale('es'),
        Locale('it'),
        Locale('pt'),
        Locale('ru'),
        Locale('hi'),
        Locale('ja'),
        Locale('ko'),
        Locale('zh'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      useOnlyLangCode: true,
      saveLocale: true,
      child: Builder(
        builder: (context) {
          AppLocale.sync(context.locale);
          return const ZoviApp();
        },
      ),
    ),
  );
}
