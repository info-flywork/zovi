import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
final class Country extends Equatable {
  const Country({
    required this.isoCode,
    required this.name,
    required this.dialCode,
  });

  final String isoCode;
  final String name;
  final String dialCode;

  static const turkey = Country(
    isoCode: 'TR',
    name: 'Türkiye',
    dialCode: '+90',
  );

  String get flagEmoji {
    final code = isoCode.toUpperCase();
    return String.fromCharCodes(
      code.runes.map((rune) => rune + 127397),
    );
  }

  bool matchesQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;

    return name.toLowerCase().contains(normalized) ||
        dialCode.contains(normalized) ||
        isoCode.toLowerCase().contains(normalized);
  }

  @override
  List<Object?> get props => [isoCode, name, dialCode];
}
