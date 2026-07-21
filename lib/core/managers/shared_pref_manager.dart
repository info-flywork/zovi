import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefManager {
  SharedPrefManager(this._prefs);

  final SharedPreferences _prefs;

  static const _firstLaunchKey = 'is_first_launch';
  static const _introDoneKey = 'intro_done';
  static const _onboardingDoneKey = 'onboarding_done';

  Future<bool> isFirstLaunch() async {
    return _prefs.getBool(_firstLaunchKey) ?? true;
  }

  Future<void> setFirstLaunchDone() async {
    await _prefs.setBool(_firstLaunchKey, false);
  }

  Future<bool> isIntroDone() async {
    return _prefs.getBool(_introDoneKey) ?? false;
  }

  Future<void> setIntroDone() async {
    await _prefs.setBool(_introDoneKey, true);
  }

  Future<bool> isOnboardingDone() async {
    return _prefs.getBool(_onboardingDoneKey) ?? false;
  }

  Future<void> setOnboardingDone() async {
    await _prefs.setBool(_onboardingDoneKey, true);
  }
}
