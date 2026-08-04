import 'package:flutter/foundation.dart';
@immutable
final class CheckInRewardItem {
  const CheckInRewardItem({
    required this.code,
    required this.coins,
    required this.messageKey,
    required this.iconKey,
    this.namedArgs = const {},
  });

  factory CheckInRewardItem.fromJson(Map<String, dynamic> json) {
    final rawArgs = json['namedArgs'];
    final namedArgs = <String, String>{};
    if (rawArgs is Map) {
      for (final entry in rawArgs.entries) {
        namedArgs['${entry.key}'] = '${entry.value}';
      }
    }
    return CheckInRewardItem(
      code: (json['code'] as String?)?.trim() ?? '',
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      messageKey: (json['messageKey'] as String?)?.trim() ?? '',
      iconKey: (json['iconKey'] as String?)?.trim() ?? 'coin',
      namedArgs: namedArgs,
    );
  }

  final String code;
  final int coins;
  final String messageKey;
  final String iconKey;
  final Map<String, String> namedArgs;
}

@immutable
final class CheckInFounderOffer {
  const CheckInFounderOffer({
    required this.titleLabel,
    required this.titleSlug,
    this.titleId,
    this.titleEmoji,
    this.stampSlug = 'founder',
    this.stampImageUrl,
    this.stampId,
  });

  factory CheckInFounderOffer.fromJson(Map<String, dynamic> json) {
    return CheckInFounderOffer(
      titleId: (json['titleId'] as String?)?.trim(),
      titleSlug: (json['titleSlug'] as String?)?.trim() ?? 'founder_king',
      titleLabel: (json['titleLabel'] as String?)?.trim() ?? 'Kurucu Kral',
      titleEmoji: (json['titleEmoji'] as String?)?.trim(),
      stampSlug: (json['stampSlug'] as String?)?.trim() ?? 'founder',
      stampImageUrl: (json['stampImageUrl'] as String?)?.trim(),
      stampId: (json['stampId'] as String?)?.trim(),
    );
  }

  final String? titleId;
  final String titleSlug;
  final String titleLabel;
  final String? titleEmoji;
  final String stampSlug;
  final String? stampImageUrl;
  final String? stampId;

  String get displayLabel {
    final emoji = titleEmoji?.trim();
    if (emoji == null || emoji.isEmpty) return titleLabel;
    return '$emoji $titleLabel';
  }
}

@immutable
final class CheckInSuccessRouteArgs {
  const CheckInSuccessRouteArgs({
    required this.placeName,
    this.friendNames = const [],
    this.hasPhoto = false,
    this.photoPaths = const [],
    this.totalCoins = 0,
    this.rewards = const [],
    this.checkInId,
    this.founderOffer,
    this.isFirstEver = false,
  });

  final String placeName;
  final List<String> friendNames;
  final bool hasPhoto;
  final List<String> photoPaths;
  final int totalCoins;
  final List<CheckInRewardItem> rewards;
  final String? checkInId;
  final CheckInFounderOffer? founderOffer;
  final bool isFirstEver;

  String? get photoPath => photoPaths.isEmpty ? null : photoPaths.first;
}
