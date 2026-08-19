abstract final class StringConstants {
  static const String appName = 'zovi';

  /// iOS/Android emulator: localhost. Fiziksel cihaz için:
  /// `--dart-define=API_BASE_URL=http://<YOUR_LAN_IP>:3000`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3000',
  );

  static const String termsUrl = 'https://fly-work.com/zovi/terms/';
  static const String profileShareHost = 'zovi.fly-work.com';
  static const String profileSharePathPrefix = '/u/';
}
