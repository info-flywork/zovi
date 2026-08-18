import 'package:flutter/foundation.dart';

@immutable
final class UsernameTakenException implements Exception {
  const UsernameTakenException(this.suggestions);

  final List<String> suggestions;

  @override
  String toString() => 'UsernameTakenException($suggestions)';
}
