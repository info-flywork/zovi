import 'package:equatable/equatable.dart';
import 'package:zovi/core/models/country.dart';

class OtpRouteArgs extends Equatable {
  const OtpRouteArgs({
    required this.phone,
    required this.selectedCountry,
  });

  final String phone;
  final Country selectedCountry;

  @override
  List<Object?> get props => [phone, selectedCountry];
}
