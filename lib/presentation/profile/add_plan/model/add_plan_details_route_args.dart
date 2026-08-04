import 'package:zovi/presentation/profile/add_plan/model/add_plan_place.dart';
import 'package:flutter/foundation.dart';

@immutable
final class AddPlanDetailsRouteArgs {
  const AddPlanDetailsRouteArgs({required this.place});

  final AddPlanPlace place;
}
