import 'package:zovi/presentation/profile/add_plan/model/add_plan_place.dart';
import 'package:flutter/foundation.dart';

@immutable
final class AddPlanSuccessRouteArgs {
  const AddPlanSuccessRouteArgs({
    required this.place,
    required this.showToFriends,
    required this.showToNearby,
  });

  final AddPlanPlace place;
  final bool showToFriends;
  final bool showToNearby;
}
