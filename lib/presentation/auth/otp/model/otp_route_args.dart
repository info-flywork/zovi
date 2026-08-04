import 'package:equatable/equatable.dart';
import 'package:zovi/core/models/country.dart';
import 'package:flutter/foundation.dart';

@immutable
final class OtpRouteArgs extends Equatable {
  const OtpRouteArgs({
    required this.phone,
    required this.selectedCountry,
  });

  final String phone;
  final Country selectedCountry;

  @override
  List<Object?> get props => [phone, selectedCountry];
}
