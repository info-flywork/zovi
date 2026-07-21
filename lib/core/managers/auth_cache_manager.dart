import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthCacheManager {
  AuthCacheManager(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
