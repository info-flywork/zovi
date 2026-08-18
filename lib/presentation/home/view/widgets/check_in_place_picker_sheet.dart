import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/domain/user/user_repository.dart';

/// Same nearby list as Plan Ekle — pick one for check-in.
Future<NearbyAddPlanPlace?> showCheckInPlacePickerSheet(
  BuildContext context, {
  required List<NearbyAddPlanPlace> places,
  NearbyAddPlanPlace? selected,
}) {
  return showModalBottomSheet<NearbyAddPlanPlace>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) =>
        _CheckInPlacePickerSheet(places: places, selected: selected),
  );
}

@immutable
final class _CheckInPlacePickerSheet extends StatelessWidget {
  const _CheckInPlacePickerSheet({
    required this.places,
    required this.selected,
  });

  final List<NearbyAddPlanPlace> places;
  final NearbyAddPlanPlace? selected;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: maxHeight,
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 46,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const AppIcon(AssetPaths.iconLocationOutlined, size: 24),
                  const SizedBox(width: 6),
                  Text(
                    'nearby_places'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      letterSpacing: -0.32,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: places.isEmpty
                  ? Center(
                      child: Text(
                        'check_in_venue_empty'.tr(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: places.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final place = places[index];
                        final isSelected =
                            selected?.placeName == place.placeName &&
                            selected?.lat == place.lat &&
                            selected?.lng == place.lng;
                        return Material(
                          color: isSelected
                              ? AppColors.zoviOrange.withValues(alpha: 0.08)
                              : const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.of(context).pop(place),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          place.placeName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            height: 20 / 16,
                                            letterSpacing: -0.32,
                                            color: AppColors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          place.subtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            height: 16 / 13,
                                            color: AppColors.deepRoast
                                                .withValues(alpha: 0.55),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    place.distanceLabel,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.zoviOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
