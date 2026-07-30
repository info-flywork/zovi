class UsernameTakenException implements Exception {
  UsernameTakenException(this.suggestions);

  final List<String> suggestions;

  @override
  String toString() => 'UsernameTakenException($suggestions)';
}
