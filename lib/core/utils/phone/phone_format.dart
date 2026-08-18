import 'package:flutter/foundation.dart';

@immutable
final class PhoneFormat {
  const PhoneFormat({
    required this.maxDigits,
    required this.groups,
    required this.example,
  });

  final int maxDigits;
  final List<int> groups;
  final String example;

  String limitDigits(String digits) {
    final onlyDigits = digits.replaceAll(RegExp(r'\D'), '');
    if (onlyDigits.length <= maxDigits) return onlyDigits;
    return onlyDigits.substring(0, maxDigits);
  }

  bool isComplete(String digits) => limitDigits(digits).length == maxDigits;

  String formatDigits(String digits) {
    final limited = limitDigits(digits);
    if (limited.isEmpty) return '';

    final buffer = StringBuffer();
    var index = 0;

    for (final group in groups) {
      if (index >= limited.length) break;
      if (buffer.isNotEmpty) buffer.write(' ');
      final end = (index + group).clamp(0, limited.length);
      buffer.write(limited.substring(index, end));
      index += group;
    }

    if (index < limited.length) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(limited.substring(index));
    }

    return buffer.toString();
  }
}

abstract final class PhoneFormats {
  static const PhoneFormat turkey = PhoneFormat(
    maxDigits: 10,
    groups: [3, 3, 2, 2],
    example: '123 456 78 90',
  );

  static const PhoneFormat unitedStates = PhoneFormat(
    maxDigits: 10,
    groups: [3, 3, 4],
    example: '201 555 0123',
  );

  static const PhoneFormat unitedKingdom = PhoneFormat(
    maxDigits: 10,
    groups: [4, 3, 3],
    example: '7911 123 456',
  );

  static const PhoneFormat germany = PhoneFormat(
    maxDigits: 11,
    groups: [3, 3, 4],
    example: '151 234 5678',
  );

  static const PhoneFormat france = PhoneFormat(
    maxDigits: 9,
    groups: [1, 2, 2, 2, 2],
    example: '6 12 34 56 78',
  );

  static const PhoneFormat defaultFormat = PhoneFormat(
    maxDigits: 15,
    groups: [3, 3, 3, 3, 3],
    example: '123 456 789',
  );

  static final Map<String, PhoneFormat> _byIso = {
    'TR': turkey,
    'US': unitedStates,
    'CA': unitedStates,
    'GB': unitedKingdom,
    'DE': germany,
    'FR': france,
    'IT': PhoneFormat(maxDigits: 10, groups: [3, 3, 4], example: '312 345 6789'),
    'ES': PhoneFormat(maxDigits: 9, groups: [3, 3, 3], example: '612 345 678'),
    'NL': PhoneFormat(maxDigits: 9, groups: [1, 2, 3, 4], example: '6 12 345 678'),
    'BE': PhoneFormat(maxDigits: 9, groups: [3, 2, 2, 2], example: '470 12 34 56'),
    'CH': PhoneFormat(maxDigits: 9, groups: [2, 3, 2, 2], example: '78 123 45 67'),
    'AT': PhoneFormat(maxDigits: 10, groups: [3, 3, 4], example: '664 123 4567'),
    'SE': PhoneFormat(maxDigits: 9, groups: [2, 3, 2, 2], example: '70 123 45 67'),
    'NO': PhoneFormat(maxDigits: 8, groups: [3, 2, 3], example: '412 34 567'),
    'DK': PhoneFormat(maxDigits: 8, groups: [2, 2, 2, 2], example: '12 34 56 78'),
    'FI': PhoneFormat(maxDigits: 10, groups: [2, 3, 3, 2], example: '41 234 5678'),
    'PL': PhoneFormat(maxDigits: 9, groups: [3, 3, 3], example: '512 345 678'),
    'GR': PhoneFormat(maxDigits: 10, groups: [3, 3, 4], example: '691 234 5678'),
    'PT': PhoneFormat(maxDigits: 9, groups: [3, 3, 3], example: '912 345 678'),
    'RU': PhoneFormat(maxDigits: 10, groups: [3, 3, 2, 2], example: '912 345 67 89'),
    'UA': PhoneFormat(maxDigits: 9, groups: [2, 3, 2, 2], example: '50 123 45 67'),
    'AE': PhoneFormat(maxDigits: 9, groups: [2, 3, 4], example: '50 123 4567'),
    'SA': PhoneFormat(maxDigits: 9, groups: [2, 3, 4], example: '50 123 4567'),
    'IN': PhoneFormat(maxDigits: 10, groups: [5, 5], example: '98765 43210'),
    'CN': PhoneFormat(maxDigits: 11, groups: [3, 4, 4], example: '131 2345 6789'),
    'JP': PhoneFormat(maxDigits: 10, groups: [2, 4, 4], example: '90 1234 5678'),
    'KR': PhoneFormat(maxDigits: 10, groups: [3, 4, 3], example: '010 1234 567'),
    'AU': PhoneFormat(maxDigits: 9, groups: [3, 3, 3], example: '412 345 678'),
    'NZ': PhoneFormat(maxDigits: 9, groups: [2, 3, 4], example: '21 234 5678'),
    'BR': PhoneFormat(maxDigits: 11, groups: [2, 5, 4], example: '11 91234 5678'),
    'MX': PhoneFormat(maxDigits: 10, groups: [3, 3, 4], example: '222 123 4567'),
    'AR': PhoneFormat(maxDigits: 10, groups: [2, 4, 4], example: '11 2345 6789'),
    'ZA': PhoneFormat(maxDigits: 9, groups: [2, 3, 4], example: '82 123 4567'),
    'EG': PhoneFormat(maxDigits: 10, groups: [3, 3, 4], example: '100 123 4567'),
    'NG': PhoneFormat(maxDigits: 10, groups: [3, 3, 4], example: '802 123 4567'),
    'IL': PhoneFormat(maxDigits: 9, groups: [2, 3, 4], example: '50 123 4567'),
    'SG': PhoneFormat(maxDigits: 8, groups: [4, 4], example: '8123 4567'),
    'MY': PhoneFormat(maxDigits: 10, groups: [2, 3, 4], example: '12 345 6789'),
    'TH': PhoneFormat(maxDigits: 9, groups: [2, 3, 4], example: '81 234 5678'),
    'ID': PhoneFormat(maxDigits: 11, groups: [3, 4, 4], example: '812 3456 7890'),
    'PH': PhoneFormat(maxDigits: 10, groups: [3, 3, 4], example: '917 123 4567'),
    'VN': PhoneFormat(maxDigits: 9, groups: [3, 3, 3], example: '912 345 678'),
    'PK': PhoneFormat(maxDigits: 10, groups: [3, 3, 4], example: '301 234 5678'),
    'BD': PhoneFormat(maxDigits: 10, groups: [4, 6], example: '1712 345678'),
    'IR': PhoneFormat(maxDigits: 10, groups: [3, 3, 4], example: '912 345 6789'),
    'IQ': PhoneFormat(maxDigits: 10, groups: [3, 3, 4], example: '790 123 4567'),
    'AZ': PhoneFormat(maxDigits: 9, groups: [2, 3, 2, 2], example: '50 123 45 67'),
    'KZ': PhoneFormat(maxDigits: 10, groups: [3, 3, 2, 2], example: '701 234 56 78'),
    'RO': PhoneFormat(maxDigits: 9, groups: [3, 3, 3], example: '712 345 678'),
    'CZ': PhoneFormat(maxDigits: 9, groups: [3, 3, 3], example: '601 234 567'),
    'HU': PhoneFormat(maxDigits: 9, groups: [2, 3, 4], example: '20 123 4567'),
    'IE': PhoneFormat(maxDigits: 9, groups: [2, 3, 4], example: '85 123 4567'),
  };

  static PhoneFormat forCountry(String isoCode) {
    return _byIso[isoCode.toUpperCase()] ?? defaultFormat;
  }

  /// Formats E.164 (`+905321234567`) as `+90 532 123 45 67` using country rules.
  static String formatE164(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    final hasPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return trimmed;

    final match = _matchDialCode(digits);
    if (match == null) {
      final grouped = defaultFormat.formatDigits(digits);
      return hasPlus || trimmed.startsWith('+') ? '+$grouped' : grouped;
    }

    final dialDigits = match.dialCode.replaceAll(RegExp(r'\D'), '');
    final national = digits.substring(dialDigits.length);
    final format = forCountry(match.isoCode);
    final nationalFormatted = format.formatDigits(national);
    if (nationalFormatted.isEmpty) return match.dialCode;
    return '${match.dialCode} $nationalFormatted';
  }

  static ({String isoCode, String dialCode})? _matchDialCode(String digits) {
    // Longest dial-code match first (+994 before +9…).
    final candidates = <({String isoCode, String dialCode, int len})>[];
    for (final entry in _dialCodeByIso.entries) {
      final dialDigits = entry.value.replaceAll(RegExp(r'\D'), '');
      if (dialDigits.isEmpty) continue;
      if (digits.startsWith(dialDigits)) {
        candidates.add((
          isoCode: entry.key,
          dialCode: entry.value.startsWith('+')
              ? entry.value
              : '+${entry.value}',
          len: dialDigits.length,
        ));
      }
    }
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.len.compareTo(a.len));
    final bestLen = candidates.first.len;
    final sameLen = candidates.where((c) => c.len == bestLen).toList();
    final dialKey = sameLen.first.dialCode.replaceAll(RegExp(r'\D'), '');
    final preferred = _preferredIsoByDial[dialKey];
    if (preferred != null) {
      for (final c in sameLen) {
        if (c.isoCode == preferred) {
          return (isoCode: c.isoCode, dialCode: c.dialCode);
        }
      }
    }
    final best = sameLen.first;
    return (isoCode: best.isoCode, dialCode: best.dialCode);
  }

  /// Prefer common countries when dial codes collide (e.g. +1 → US).
  static const _preferredIsoByDial = {
    '1': 'US',
    '7': 'RU',
  };

  static final Map<String, String> _dialCodeByIso = () {
    // Built lazily from Countries list via side import in formatE164 callers —
    // keep a compact map here to avoid circular imports; populated below.
    return <String, String>{
      for (final e in _isoDialPairs) e.$1: e.$2,
    };
  }();

  // iso → dial pairs used for E.164 matching (mirrors Countries dataset).
  static const _isoDialPairs = <(String, String)>[
    ('TR', '+90'),
    ('US', '+1'),
    ('CA', '+1'),
    ('GB', '+44'),
    ('DE', '+49'),
    ('FR', '+33'),
    ('IT', '+39'),
    ('ES', '+34'),
    ('NL', '+31'),
    ('BE', '+32'),
    ('CH', '+41'),
    ('AT', '+43'),
    ('SE', '+46'),
    ('NO', '+47'),
    ('DK', '+45'),
    ('FI', '+358'),
    ('PL', '+48'),
    ('GR', '+30'),
    ('PT', '+351'),
    ('RU', '+7'),
    ('UA', '+380'),
    ('AE', '+971'),
    ('SA', '+966'),
    ('IN', '+91'),
    ('CN', '+86'),
    ('JP', '+81'),
    ('KR', '+82'),
    ('AU', '+61'),
    ('NZ', '+64'),
    ('BR', '+55'),
    ('MX', '+52'),
    ('AR', '+54'),
    ('ZA', '+27'),
    ('EG', '+20'),
    ('NG', '+234'),
    ('IL', '+972'),
    ('SG', '+65'),
    ('MY', '+60'),
    ('TH', '+66'),
    ('ID', '+62'),
    ('PH', '+63'),
    ('VN', '+84'),
    ('PK', '+92'),
    ('BD', '+880'),
    ('IR', '+98'),
    ('IQ', '+964'),
    ('AZ', '+994'),
    ('KZ', '+7'),
    ('RO', '+40'),
    ('CZ', '+420'),
    ('HU', '+36'),
    ('IE', '+353'),
    ('AF', '+93'),
    ('AL', '+355'),
    ('DZ', '+213'),
    ('AD', '+376'),
    ('AO', '+244'),
    ('AM', '+374'),
    ('BH', '+973'),
    ('BY', '+375'),
    ('BA', '+387'),
    ('BG', '+359'),
    ('CL', '+56'),
    ('CO', '+57'),
    ('HR', '+385'),
    ('CY', '+357'),
    ('EE', '+372'),
    ('GE', '+995'),
    ('HK', '+852'),
    ('IS', '+354'),
    ('JO', '+962'),
    ('KE', '+254'),
    ('KW', '+965'),
    ('LV', '+371'),
    ('LB', '+961'),
    ('LT', '+370'),
    ('LU', '+352'),
    ('MT', '+356'),
    ('MA', '+212'),
    ('NP', '+977'),
    ('OM', '+968'),
    ('PE', '+51'),
    ('QA', '+974'),
    ('RS', '+381'),
    ('SK', '+421'),
    ('SI', '+386'),
    ('LK', '+94'),
    ('SY', '+963'),
    ('TW', '+886'),
    ('TN', '+216'),
    ('TM', '+993'),
    ('UZ', '+998'),
  ];
}
