import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

String mapPhoneAuthError(Object error) {
  if (error is FirebaseAuthException) {
    final details = '${error.message ?? ''} $error'.toLowerCase();
    final looksLikeBilling = details.contains('billing_not_enabled') ||
        details.contains('billing not enabled');

    final mapped = switch (error.code) {
      'too-many-requests' => 'error_phone_too_many_requests'.tr(),
      'invalid-phone-number' => 'error_invalid_phone'.tr(),
      'quota-exceeded' => 'error_phone_quota'.tr(),
      'captcha-check-failed' ||
      'missing-client-identifier' ||
      'invalid-app-credential' ||
      'app-not-authorized' =>
        'error_phone_app_verify'.tr(),
      'operation-not-allowed' => 'error_phone_not_enabled'.tr(),
      'session-expired' => 'error_phone_session_expired'.tr(),
      'internal-error' when looksLikeBilling => 'error_phone_billing'.tr(),
      'unknown' when looksLikeBilling => 'error_phone_billing'.tr(),
      'internal-error' => 'error_phone_billing'.tr(),
      _ => 'error_send_code_failed'.tr(),
    };
    if (kDebugMode) {
      return '$mapped (${error.code})';
    }
    return mapped;
  }
  return 'error_send_code_failed'.tr();
}
