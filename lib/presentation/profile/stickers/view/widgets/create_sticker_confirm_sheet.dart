import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_button.dart';
import 'package:zovi/core/widgets/app_icon.dart';

const stickerCreateCoinCost = 50;

enum CreateStickerConfirmAction { create, buyCoins }

Future<CreateStickerConfirmAction?> showCreateStickerConfirmSheet(
  BuildContext context, {
  required int coinBalance,
  int coinCost = stickerCreateCoinCost,
  String? titleText,
  String? subtitleText,
  String? costLabelText,
  String? balanceLabelText,
  String? confirmLabelText,
  String? buyCoinsLabelText,
}) {
  return showModalBottomSheet<CreateStickerConfirmAction>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => CreateStickerConfirmSheet(
      coinBalance: coinBalance,
      coinCost: coinCost,
      titleText: titleText,
      subtitleText: subtitleText,
      costLabelText: costLabelText,
      balanceLabelText: balanceLabelText,
      confirmLabelText: confirmLabelText,
      buyCoinsLabelText: buyCoinsLabelText,
    ),
  );
}

@immutable
final class CreateStickerConfirmSheet extends StatelessWidget {
  const CreateStickerConfirmSheet({
    required this.coinBalance,
    this.coinCost = stickerCreateCoinCost,
    this.titleText,
    this.subtitleText,
    this.costLabelText,
    this.balanceLabelText,
    this.confirmLabelText,
    this.buyCoinsLabelText,
    super.key,
  });

  final int coinBalance;
  final int coinCost;
  final String? titleText;
  final String? subtitleText;
  final String? costLabelText;
  final String? balanceLabelText;
  final String? confirmLabelText;
  final String? buyCoinsLabelText;

  bool get _hasEnoughCoins => coinBalance >= coinCost;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: const AppIcon(AssetPaths.iconCloseCircle, size: 32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              titleText ?? 'sticker_create_sheet_title'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1,
                letterSpacing: -0.4,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitleText ??
                  'sticker_create_sheet_subtitle'.tr(
                    namedArgs: {'count': '$coinCost'},
                  ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                height: 24 / 20,
                letterSpacing: -0.4,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            _CoinInfoCard(
              child: _CoinInfoRow(
                label: costLabelText ?? 'sticker_create_sheet_cost_label'.tr(),
                amount: coinCost,
              ),
            ),
            const SizedBox(height: 10),
            _CoinInfoCard(
              child: _CoinInfoRow(
                label:
                    balanceLabelText ?? 'sticker_create_sheet_balance_label'.tr(),
                amount: coinBalance,
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: _hasEnoughCoins
                  ? (confirmLabelText ??
                      'sticker_create_sheet_confirm'.tr(
                        namedArgs: {'count': '$coinCost'},
                      ))
                  : (buyCoinsLabelText ?? 'sticker_create_sheet_buy_coins'.tr()),
              onPressed: () => Navigator.of(context).pop(
                _hasEnoughCoins
                    ? CreateStickerConfirmAction.create
                    : CreateStickerConfirmAction.buyCoins,
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'cancel'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 20 / 16,
                    color: AppColors.deepRoast,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
final class _CoinInfoRow extends StatelessWidget {
  const _CoinInfoRow({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1,
              letterSpacing: -0.32,
              color: AppColors.black,
            ),
          ),
        ),
        Text(
          'sticker_create_sheet_tokens'.tr(namedArgs: {'count': '$amount'}),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1,
            letterSpacing: -0.32,
            color: AppColors.zoviOrange,
          ),
        ),
        const SizedBox(width: 4),
        Image.asset(
          AssetPaths.zoviCoin,
          width: 24,
          height: 24,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}

@immutable
final class _CoinInfoCard extends StatelessWidget {
  const _CoinInfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.chatPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}
