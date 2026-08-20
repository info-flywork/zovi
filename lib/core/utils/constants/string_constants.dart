abstract final class StringConstants {
  static const String appName = 'zovi';

  /// Live API. Local için:
  /// `--dart-define=API_BASE_URL=http://127.0.0.1:3000`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://zovi.fly-work.com',
  );

  static const String termsUrl = 'https://fly-work.com/zovi/terms/';
  static const String privacyUrl = 'https://fly-work.com/zovi/privacy-policy/';
  static const String cookiesUrl = 'https://fly-work.com/zovi/cookies/';
  static const String profileShareHost = 'zovi.fly-work.com';
  static const String profileSharePathPrefix = '/u/';
}
