import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:zovi/core/billing/revenuecat_service.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/snackbar/app_snackbar.dart';
import 'package:zovi/core/utils/extensions/future_extensions.dart';
import 'package:zovi/domain/user/user_repository.dart';

/// Opens the RevenueCat paywall and applies the new coin balance locally.
Future<bool> openZoviCoinPaywall(BuildContext context) async {
  final billing = getIt<RevenueCatService>();
  if (!billing.isConfigured) {
    if (context.mounted) {
      AppSnackbar.instance.show(
        context,
        'billing_not_configured'.tr(),
        isError: true,
      );
    }
    return false;
  }

  try {
    final balance = await billing
        .presentPaywallAndSyncCoins()
        .withLoading(context);
    if (!context.mounted) return false;

    if (balance != null) {
      getIt<UserRepository>().applyCoinsBalance(balance);
      AppSnackbar.instance.show(
        context,
        'billing_purchase_success'.tr(),
      );
      return true;
    }
    return false;
  } on StateError catch (e) {
    if (!context.mounted) return false;
    if (e.message == 'billing_packages_unavailable') {
      AppSnackbar.instance.show(
        context,
        'billing_packages_unavailable'.tr(),
        isError: true,
      );
      return false;
    }
    rethrow;
  } catch (_) {
    if (!context.mounted) return false;
    AppSnackbar.instance.show(
      context,
      'billing_packages_unavailable'.tr(),
      isError: true,
    );
    return false;
  }
}
