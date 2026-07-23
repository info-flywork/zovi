class CheckInSuccessRouteArgs {
  const CheckInSuccessRouteArgs({
    required this.placeName,
    this.friendNames = const [],
    this.hasPhoto = false,
    this.photoPaths = const [],
    this.totalCoins = 150,
  });

  final String placeName;
  final List<String> friendNames;
  final bool hasPhoto;
  final List<String> photoPaths;
  final int totalCoins;

  String? get photoPath => photoPaths.isEmpty ? null : photoPaths.first;
}
