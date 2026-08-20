import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:zovi/core/config/revenuecat_config.dart';

typedef ConfirmIapPurchase =
    Future<int?> Function({
      required String productId,
      required String transactionId,
      String? store,
    });

/// RevenueCat paywall + purchase bridge for Zovi coin packs.
final class RevenueCatService {
  RevenueCatService();

  bool _configured = false;
  ConfirmIapPurchase? _confirmPurchase;

  bool get isConfigured => _configured && RevenueCatConfig.isConfigured;

  /// Injected after DI so purchases can credit coins on our backend immediately.
  // ignore: use_setters_to_change_properties
  void attachConfirmPurchase(ConfirmIapPurchase confirm) {
    _confirmPurchase = confirm;
  }

  Future<void> configure({String? appUserId}) async {
    if (!RevenueCatConfig.isConfigured) {
      developer.log('RevenueCat API key missing', name: 'RevenueCat');
      return;
    }
    if (_configured) {
      if (appUserId != null && appUserId.isNotEmpty) {
        await login(appUserId);
      }
      return;
    }

    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);
    final configuration = PurchasesConfiguration(RevenueCatConfig.apiKey);
    if (appUserId != null && appUserId.isNotEmpty) {
      configuration.appUserID = appUserId;
    }
    await Purchases.configure(configuration);
    _configured = true;
  }

  Future<void> login(String userId) async {
    final id = userId.trim();
    if (!_configured || id.isEmpty) return;
    try {
      await Purchases.logIn(id);
    } catch (e, st) {
      developer.log('login failed', name: 'RevenueCat', error: e, stackTrace: st);
    }
  }

  Future<void> logout() async {
    if (!_configured) return;
    try {
      await Purchases.logOut();
    } catch (e, st) {
      developer.log(
        'logout failed',
        name: 'RevenueCat',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<Offerings?> getOfferings() async {
    if (!_configured) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e, st) {
      developer.log(
        'getOfferings failed',
        name: 'RevenueCat',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Resolves the active offering (`default` preferred) with store packages.
  Future<Offering?> resolveOffering() async {
    final offerings = await getOfferings();
    if (offerings == null) return null;

    final preferred = offerings.getOffering(RevenueCatConfig.defaultOfferingId);
    final offering = preferred ?? offerings.current;
    final packages = offering?.availablePackages ?? const <Package>[];

    developer.log(
      'offering=${offering?.identifier} packages=${packages.length} '
      'ids=${packages.map((p) => p.storeProduct.identifier).join(',')}',
      name: 'RevenueCat',
    );

    return offering;
  }

  /// Shows the RevenueCat paywall for the current (default) offering.
  Future<PaywallResult> presentPaywall({Offering? offering}) async {
    if (!_configured) return PaywallResult.error;
    try {
      final resolved = offering ?? await resolveOffering();
      return await RevenueCatUI.presentPaywall(
        offering: resolved,
        displayCloseButton: true,
      );
    } catch (e, st) {
      developer.log(
        'presentPaywall failed',
        name: 'RevenueCat',
        error: e,
        stackTrace: st,
      );
      return PaywallResult.error;
    }
  }

  /// Purchase a single package without the hosted paywall UI.
  Future<CustomerInfo?> purchasePackage(Package package) async {
    if (!_configured) return null;
    try {
      final result = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      return result.customerInfo;
    } catch (e, st) {
      developer.log(
        'purchasePackage failed',
        name: 'RevenueCat',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<CustomerInfo?> restorePurchases() async {
    if (!_configured) return null;
    try {
      return await Purchases.restorePurchases();
    } catch (e, st) {
      developer.log(
        'restorePurchases failed',
        name: 'RevenueCat',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Opens paywall; on purchase/restore, credits coins via backend and returns
  /// the latest balance (null if cancelled / no credit).
  ///
  /// Throws [StateError] with code-friendly message when packages failed to
  /// load from the store (paywall would hide the token list).
  Future<int?> presentPaywallAndSyncCoins({Offering? offering}) async {
    final resolved = offering ?? await resolveOffering();
    final packages = resolved?.availablePackages ?? const <Package>[];
    if (packages.isEmpty) {
      throw StateError('billing_packages_unavailable');
    }

    final result = await presentPaywall(offering: resolved);
    if (result != PaywallResult.purchased && result != PaywallResult.restored) {
      return null;
    }
    return syncRecentPurchasesToBackend();
  }

  /// Pushes recent non-subscription transactions to Node so coins land ASAP
  /// (webhook remains the durable source of truth / idempotent backup).
  Future<int?> syncRecentPurchasesToBackend() async {
    final confirm = _confirmPurchase;
    if (!_configured || confirm == null) return null;

    try {
      final info = await Purchases.getCustomerInfo();
      final txs = List<StoreTransaction>.from(info.nonSubscriptionTransactions);
      if (txs.isEmpty) return null;

      txs.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
      int? latestBalance;
      // Credit the newest few — idempotent on the server by transaction id.
      for (final tx in txs.take(5)) {
        final productId = tx.productIdentifier.trim();
        final transactionId = tx.transactionIdentifier.trim();
        if (productId.isEmpty || transactionId.isEmpty) continue;
        final balance = await confirm(
          productId: productId,
          transactionId: transactionId,
          store: _storeLabel(),
        );
        if (balance != null) latestBalance = balance;
      }
      return latestBalance;
    } catch (e, st) {
      developer.log(
        'syncRecentPurchasesToBackend failed',
        name: 'RevenueCat',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  String _storeLabel() {
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'app_store';
    if (defaultTargetPlatform == TargetPlatform.android) return 'play_store';
    return 'unknown';
  }
}
