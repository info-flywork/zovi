class AddPlanPlace {
  const AddPlanPlace({
    required this.categoryKey,
    required this.placeName,
    required this.subtitle,
    required this.distanceLabel,
    required this.friendAvatars,
    required this.friendsLabel,
    this.isHighlighted = false,
  });

  final String categoryKey;
  final String placeName;
  final String subtitle;
  final String distanceLabel;
  final List<String> friendAvatars;
  final String friendsLabel;
  final bool isHighlighted;
}
