import 'package:zovi/core/managers/auth_cache_manager.dart';
import 'package:zovi/core/managers/shared_pref_manager.dart';

class AuthRepository {
  AuthRepository(this._authCache, this._prefs);

  final AuthCacheManager _authCache;
  final SharedPrefManager _prefs;

  Future<bool> isFirstLaunch() => _prefs.isFirstLaunch();

  Future<bool> isIntroDone() => _prefs.isIntroDone();

  Future<bool> isAuthenticated() async {
    final token = await _authCache.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> isOnboardingDone() => _prefs.isOnboardingDone();

  Future<void> completeIntro() async {
    await _prefs.setIntroDone();
  }

  Future<void> sendVerificationCode(String phone) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  Future<bool> verifyCode(String phone, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return code.length == 6;
  }

  Future<void> completeOnboarding({String? mockToken}) async {
    await _authCache.saveAccessToken(mockToken ?? 'demo_token');
    await _prefs.setOnboardingDone();
    await _prefs.setIntroDone();
    await _prefs.setFirstLaunchDone();
  }

  Future<void> logout() async {
    await _authCache.clearAll();
  }
}
