import 'dart:io' show Platform;

abstract final class StringConstants {
  static const String appName = 'zovi';
  static const String tagline = 'be here, share now';

  /// Opsiyonel override. Yoksa simülatör / fiziksel cihaza göre seçilir.
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Mac Wi‑Fi IP. Değişirse burayı güncelle (`ipconfig getifaddr en0`).
  static const String _lanHost = '192.168.1.105';
  static const int _apiPort = 3000;

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    return 'http://$_resolvedHost:$_apiPort';
  }

  static String get _resolvedHost {
    if (_isIosSimulator) return '127.0.0.1';
    // Fiziksel iOS/Android + Android emulator → Mac'in LAN IP'si
    return _lanHost;
  }

  static bool get _isIosSimulator =>
      Platform.isIOS &&
      Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');

  static const String termsUrl = 'https://fly-work.com/zovi/terms/';
  static const String profileShareHost = 'zovi.app';
  static const String profileSharePathPrefix = '/u/';
}
