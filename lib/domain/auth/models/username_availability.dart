import 'package:flutter/foundation.dart';
@immutable
final class UsernameAvailability {
  const UsernameAvailability({
    required this.username,
    required this.available,
    required this.valid,
    required this.suggestions,
    this.reason,
  });

  factory UsernameAvailability.fromJson(Map<String, dynamic> json) {
    final rawSuggestions = json['suggestions'];
    return UsernameAvailability(
      username: (json['username'] as String? ?? '').trim(),
      available: json['available'] == true,
      valid: json['valid'] != false,
      suggestions: rawSuggestions is List
          ? rawSuggestions.map((e) => e.toString()).toList()
          : const [],
      reason: json['reason'] as String?,
    );
  }

  final String username;
  final bool available;
  final bool valid;
  final List<String> suggestions;
  final String? reason;
}
