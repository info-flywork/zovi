import 'dart:io';

/// RevenueCat public SDK keys (safe in the client).
abstract final class RevenueCatConfig {
  static const appleApiKey = 'appl_vTpggTcmIQzjVNUURrLGIgZoKKw';
  static const googleApiKey = 'goog_iyxXAOqsysjTgrRulwMBXHXFmiO';

  /// Active offering identifier in RevenueCat dashboard.
  static const defaultOfferingId = 'default';

  static String get apiKey {
    if (Platform.isIOS) return appleApiKey;
    if (Platform.isAndroid) return googleApiKey;
    return appleApiKey;
  }

  static bool get isConfigured => apiKey.trim().isNotEmpty;
}
