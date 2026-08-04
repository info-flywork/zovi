import 'package:flutter/foundation.dart';
@immutable
final class AddPlanPlace {
  const AddPlanPlace({
    required this.categoryKey,
    required this.placeName,
    required this.subtitle,
    required this.distanceLabel,
    required this.friendAvatars,
    required this.friendsLabel,
    this.lat = 0,
    this.lng = 0,
  });

  final String categoryKey;
  final String placeName;
  final String subtitle;
  final String distanceLabel;
  final List<String> friendAvatars;
  final String friendsLabel;
  final double lat;
  final double lng;

  bool get hasCoordinates => lat != 0 || lng != 0;
}
