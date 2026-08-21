import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Current UI language code (`tr`, `en`, `ko`, …) for API `Accept-Language`.
/// Listen to [listenable] to refresh locale-dependent remote data (mock names…).
abstract final class AppLocale {
  static String languageCode = 'en';

  static final ValueNotifier<String> listenable = ValueNotifier<String>('en');

  static void sync(Locale locale) {
    final code = locale.languageCode.trim().toLowerCase();
    final next = code.isEmpty ? 'en' : code;
    languageCode = next;
    if (listenable.value != next) {
      listenable.value = next;
    }
  }
}
