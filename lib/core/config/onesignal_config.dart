/// OneSignal client config. App ID is public; REST API key stays on the server.
abstract final class OneSignalConfig {
  static const appId = 'b9f2ab22-bd55-4d22-a20f-543bee3d926c';

  static bool get isConfigured => appId.trim().isNotEmpty;
}
