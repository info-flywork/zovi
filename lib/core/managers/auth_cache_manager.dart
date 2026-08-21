import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final class AuthCacheManager {
  AuthCacheManager(this._storage);

  final FlutterSecureStorage _storage;

  /// Sliding app session. Each successful auth / resume extends this window.
  static const sessionTtl = Duration(days: 7);
  static const _accessTokenKey = 'access_token';
  static const _sessionExpiresAtKey = 'session_expires_at_ms';

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  /// Sliding 7-day app session. Re-entry before expiry resets the window.
  Future<void> touchSession() async {
    final expiresAt = DateTime.now().add(sessionTtl).millisecondsSinceEpoch;
    await _storage.write(key: _sessionExpiresAtKey, value: '$expiresAt');
  }

  /// `true` only when an explicit expiry timestamp exists and is in the past.
  /// Missing key = treat as still valid so we don't force logout before
  /// [touchSession] writes a fresh window.
  Future<bool> isSessionExpired() async {
    final raw = await _storage.read(key: _sessionExpiresAtKey);
    if (raw == null || raw.isEmpty) return false;
    final expiresAt = int.tryParse(raw);
    if (expiresAt == null) return false;
    return DateTime.now().millisecondsSinceEpoch >= expiresAt;
  }

  Future<bool> hasCachedAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
