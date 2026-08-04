import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/app_search_field.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/profile/add_plan/model/add_plan_details_route_args.dart';
import 'package:zovi/presentation/profile/add_plan/model/add_plan_place.dart';

enum _PlanCategory {
  all('category_all', ''),
  music('category_music', '🎶'),
  cafe('category_cafe', '☕'),
  park('category_park', '🏞️'),
  culture('category_culture', '🏛️'),
  restaurant('category_restaurant', '🍕'),
  gym('category_gym', '🏋️');

  const _PlanCategory(this.labelKey, this.emoji);
  final String labelKey;
  final String emoji;

  String get label => labelKey.tr();
}

class AddPlanView extends StatefulWidget {
  const AddPlanView({super.key});

  @override
  State<AddPlanView> createState() => _AddPlanViewState();
}

class _AddPlanViewState extends State<AddPlanView> {
  _PlanCategory _selectedCategory = _PlanCategory.all;
  String _searchQuery = '';
  AddPlanPlace? _selectedPlace;
  List<AddPlanPlace> _plans = const [];
  var _isLoadingPlans = true;

  @override
  void initState() {
    super.initState();
    final cached = getIt<UserRepository>().peekNearbyAddPlanPlaces(limit: 40);
    if (cached.isNotEmpty) {
      _plans = [
        for (final item in cached) _mapNearbyPlace(item),
      ];
      _isLoadingPlans = false;
    }
    unawaited(_loadNearbyPlans(silent: cached.isNotEmpty));
  }

  static AddPlanPlace _mapNearbyPlace(NearbyAddPlanPlace item) {
    return AddPlanPlace(
      categoryKey: item.categoryKey,
      placeName: item.placeName,
      subtitle: item.subtitle,
      distanceLabel: item.distanceLabel,
      friendAvatars: item.friendAvatars,
      friendsLabel: item.friendsLabel,
      lat: item.lat,
      lng: item.lng,
    );
  }

  List<AddPlanPlace> get _filteredPlans {
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    return _plans.where((plan) {
      final matchesCategory =
          _selectedCategory == _PlanCategory.all ||
          plan.categoryKey == _selectedCategory.name;
      final matchesQuery =
          normalizedQuery.isEmpty ||
          plan.placeName.toLowerCase().contains(normalizedQuery) ||
          plan.subtitle.toLowerCase().contains(normalizedQuery);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  Future<void> _loadNearbyPlans({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _isLoadingPlans = true);
    }
    try {
      final repo = getIt<UserRepository>();
      final fetched = await repo.getNearbyAddPlanPlaces(limit: 40);
      if (!mounted) return;
      setState(() {
        if (fetched.isNotEmpty) {
          _plans = [for (final item in fetched) _mapNearbyPlace(item)];
        }
        _isLoadingPlans = false;
      });
    } catch (_) {
      if (kDebugMode) {
        debugPrint('AddPlanView: nearby places fetch failed');
      }
      if (!mounted) return;
      setState(() => _isLoadingPlans = false);
    }
  }

  void _onTapPlan(AddPlanPlace place) {
    setState(() {
      _selectedPlace = _selectedPlace?.placeName == place.placeName
          ? null
          : place;
    });
  }

  void _continue() {
    final place = _selectedPlace;
    if (place == null) return;
    context.push(
      RoutePaths.addPlanDetails.path,
      extra: AddPlanDetailsRouteArgs(place: place),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _AddPlanHeader(),
            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      children: [
                        AppSearchField(
                          hintText: 'search_places_hint'.tr(),
                          onDebouncedChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        _CategoryFilterRow(
                          selectedCategory: _selectedCategory,
                          onCategoryTap: (category) {
                            setState(() => _selectedCategory = category);
                          },
                        ),
                        const SizedBox(height: 20),
                        const _NearbyTitle(),
                        const SizedBox(height: 12),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              final offsetAnimation = Tween<Offset>(
                                begin: const Offset(0.04, 0),
                                end: Offset.zero,
                              ).animate(animation);
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: offsetAnimation,
                                  child: child,
                                ),
                              );
                            },
                            child: _isLoadingPlans
                                ? const _PlanListShimmer(
                                    key: ValueKey('loading_plan_state'),
                                  )
                                : _filteredPlans.isEmpty
                                ? const _EmptyPlanState(
                                    key: ValueKey('empty_plan_state'),
                                  )
                                : _PlanList(
                                    key: ValueKey(_selectedCategory),
                                    plans: _filteredPlans,
                                    selectedPlaceName:
                                        _selectedPlace?.placeName,
                                    onTapPlan: _onTapPlan,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _ContinueButton(
                      enabled: _selectedPlace != null,
                      onTap: _continue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPlanState extends StatelessWidget {
  const _EmptyPlanState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon(AssetPaths.iconSearch, size: 40),
          const SizedBox(height: 12),
          Text(
            'no_places_found'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1,
              letterSpacing: -0.32,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPlanHeader extends StatelessWidget {
  const _AddPlanHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              behavior: HitTestBehavior.opaque,
              child: const AppIcon(AssetPaths.iconBack, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'add_plan_title'.tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1,
                letterSpacing: -0.32,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterRow extends StatelessWidget {
  const _CategoryFilterRow({
    required this.selectedCategory,
    required this.onCategoryTap,
  });

  final _PlanCategory selectedCategory;
  final ValueChanged<_PlanCategory> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        itemCount: _PlanCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _PlanCategory.values[index];
          final selected = category == selectedCategory;
          return GestureDetector(
            onTap: () => onCategoryTap(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: BoxDecoration(
                color: selected ? AppColors.zoviOrange : AppColors.white,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(
                  color: selected
                      ? AppColors.zoviOrange
                      : const Color(0xFFE2E2E2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (category.emoji.isNotEmpty) ...[
                    Text(category.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    category.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1,
                      letterSpacing: -0.32,
                      color: selected ? AppColors.white : AppColors.deepRoast,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NearbyTitle extends StatelessWidget {
  const _NearbyTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppIcon(AssetPaths.iconLocationOutlined, size: 24),
        const SizedBox(width: 8),
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
    );
  }
}

class _PlanList extends StatelessWidget {
  const _PlanList({
    required super.key,
    required this.plans,
    required this.selectedPlaceName,
    required this.onTapPlan,
  });

  final List<AddPlanPlace> plans;
  final String? selectedPlaceName;
  final ValueChanged<AddPlanPlace> onTapPlan;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 140),
      itemCount: plans.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final plan = plans[index];
        return _NearbyPlanCard(
          plan: plan,
          isSelected: plan.placeName == selectedPlaceName,
          onTap: () => onTapPlan(plan),
        );
      },
    );
  }
}

class _PlanListShimmer extends StatelessWidget {
  const _PlanListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEDEDED),
      highlightColor: const Color(0xFFF8F8F8),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => Container(
          height: 104,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E2E2)),
          ),
        ),
      ),
    );
  }
}

class _NearbyPlanCard extends StatelessWidget {
  const _NearbyPlanCard({
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  final AddPlanPlace plan;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppColors.zoviOrange
        : const Color(0xFFE2E2E2);
    final backgroundColor = isSelected
        ? AppColors.zoviOrange.withValues(alpha: 0.10)
        : AppColors.white;

    final hasFriends = plan.friendAvatars.isNotEmpty;
    final friendsText = hasFriends
        ? 'friends_are_joining'.tr(namedArgs: {'count': plan.friendsLabel})
        : 'no_friends_joining'.tr();

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.placeName,
                    style: const TextStyle(
                      fontSize: 31 / 2,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      letterSpacing: -0.32,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    plan.subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1,
                      letterSpacing: -0.28,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    plan.distanceLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1,
                      letterSpacing: -0.28,
                      color: AppColors.zoviOrange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _AvatarPile(avatars: plan.friendAvatars),
            const SizedBox(width: 8),
            Text(
              friendsText,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.2,
                letterSpacing: -0.24,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarPile extends StatelessWidget {
  const _AvatarPile({required this.avatars});

  final List<String> avatars;

  @override
  Widget build(BuildContext context) {
    if (avatars.isEmpty) {
      return const SizedBox.shrink();
    }
    const size = 34.0;
    const overlap = 11.0;
    final shown = avatars.take(3).toList();
    final width = size + (shown.length - 1) * (size - overlap);

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 3),
                ),
                child: ClipOval(
                  child: Image.asset(shown[i], fit: BoxFit.cover),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.paddingOf(context).bottom + 8,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          behavior: HitTestBehavior.opaque,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: enabled ? 1 : 0.4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.deepRoast,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: Text(
                  'continue'.tr(),
                  style: const TextStyle(
                    fontSize: 34 / 2,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    letterSpacing: -0.34,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
