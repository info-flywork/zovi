import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/presentation/profile/add_plan/model/add_plan_details_route_args.dart';
import 'package:zovi/presentation/profile/add_plan/model/add_plan_place.dart';

enum _PlanCategory {
  all('All', ''),
  music('Music', '🎶'),
  cafe('Cafe', '☕'),
  park('Park', '🏞️'),
  culture('Kultur', '🏛️'),
  restaurant('Restaurant', '🍕');

  const _PlanCategory(this.label, this.emoji);
  final String label;
  final String emoji;
}

class AddPlanView extends StatefulWidget {
  const AddPlanView({super.key});

  @override
  State<AddPlanView> createState() => _AddPlanViewState();
}

class _AddPlanViewState extends State<AddPlanView> {
  _PlanCategory _selectedCategory = _PlanCategory.all;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';

  static const List<AddPlanPlace> _mockPlans = [
    AddPlanPlace(
      categoryKey: 'music',
      placeName: 'Babylon istanbul',
      subtitle: 'Konser · Beyoglu',
      distanceLabel: '800m',
      friendAvatars: [
        AssetPaths.avatarLyra,
        AssetPaths.avatarSona,
        AssetPaths.avatarJessica,
      ],
      friendsLabel: '5+ friends\nare joining',
      isHighlighted: true,
    ),
    AddPlanPlace(
      categoryKey: 'music',
      placeName: 'Salon IKSV',
      subtitle: 'Konser · Sisane',
      distanceLabel: '1.2km',
      friendAvatars: [
        AssetPaths.avatarLyra,
        AssetPaths.avatarSona,
        AssetPaths.avatarJessica,
      ],
      friendsLabel: '5+ friends\nare joining',
    ),
    AddPlanPlace(
      categoryKey: 'cafe',
      placeName: 'Blue Bottle Coffee',
      subtitle: 'Cafe · Karakoy',
      distanceLabel: '600m',
      friendAvatars: [
        AssetPaths.avatarJessica,
        AssetPaths.avatarNova,
        AssetPaths.avatarJulia,
      ],
      friendsLabel: '3+ friends\nare joining',
      isHighlighted: true,
    ),
    AddPlanPlace(
      categoryKey: 'cafe',
      placeName: 'MOC Istanbul',
      subtitle: 'Cafe · Nisantasi',
      distanceLabel: '1.8km',
      friendAvatars: [
        AssetPaths.avatarNova,
        AssetPaths.avatarLyra,
        AssetPaths.avatarSona,
      ],
      friendsLabel: '2+ friends\nare joining',
    ),
    AddPlanPlace(
      categoryKey: 'park',
      placeName: 'Maçka Parki',
      subtitle: 'Park · Sisli',
      distanceLabel: '900m',
      friendAvatars: [
        AssetPaths.avatarSona,
        AssetPaths.avatarJessica,
        AssetPaths.avatarNova,
      ],
      friendsLabel: '4+ friends\nare joining',
      isHighlighted: true,
    ),
    AddPlanPlace(
      categoryKey: 'park',
      placeName: 'Gulhane Parki',
      subtitle: 'Park · Fatih',
      distanceLabel: '2.1km',
      friendAvatars: [
        AssetPaths.avatarNova,
        AssetPaths.avatarLyra,
        AssetPaths.avatarJessica,
      ],
      friendsLabel: '3+ friends\nare joining',
    ),
    AddPlanPlace(
      categoryKey: 'culture',
      placeName: 'Pera Muzesi',
      subtitle: 'Kultur · Beyoglu',
      distanceLabel: '1.0km',
      friendAvatars: [
        AssetPaths.avatarJulia,
        AssetPaths.avatarSona,
        AssetPaths.avatarLyra,
      ],
      friendsLabel: '6+ friends\nare joining',
      isHighlighted: true,
    ),
    AddPlanPlace(
      categoryKey: 'culture',
      placeName: 'Arter',
      subtitle: 'Kultur · Dolapdere',
      distanceLabel: '2.4km',
      friendAvatars: [
        AssetPaths.avatarJessica,
        AssetPaths.avatarNova,
        AssetPaths.avatarSona,
      ],
      friendsLabel: '2+ friends\nare joining',
    ),
    AddPlanPlace(
      categoryKey: 'restaurant',
      placeName: 'Ciya Sofrasi',
      subtitle: 'Restaurant · Kadikoy',
      distanceLabel: '1.9km',
      friendAvatars: [
        AssetPaths.avatarLyra,
        AssetPaths.avatarJulia,
        AssetPaths.avatarSona,
      ],
      friendsLabel: '7+ friends\nare joining',
      isHighlighted: true,
    ),
    AddPlanPlace(
      categoryKey: 'restaurant',
      placeName: 'Mikla',
      subtitle: 'Restaurant · Beyoglu',
      distanceLabel: '2.7km',
      friendAvatars: [
        AssetPaths.avatarNova,
        AssetPaths.avatarJessica,
        AssetPaths.avatarJulia,
      ],
      friendsLabel: '4+ friends\nare joining',
    ),
  ];

  List<AddPlanPlace> get _filteredPlans {
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    return _mockPlans.where((plan) {
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _searchQuery = _searchController.text);
    });
  }

  void _openDetails(AddPlanPlace place) {
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
        child: Column(
          children: [
            const _AddPlanHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: [
                    _SearchBar(controller: _searchController),
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
                        child: _filteredPlans.isEmpty
                            ? const _EmptyPlanState(
                                key: ValueKey('empty_plan_state'),
                              )
                            : _PlanList(
                                key: ValueKey(_selectedCategory),
                                plans: _filteredPlans,
                                onTapPlan: _openDetails,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const _ContinueButton(),
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
        children: const [
          AppIcon(AssetPaths.iconSearch, size: 40),
          SizedBox(height: 12),
          Text(
            'No places found',
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
            const Text(
              'Add Plan',
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

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F9),
        borderRadius: BorderRadius.circular(99999),
      ),
      child: Row(
        children: [
          const AppIcon(AssetPaths.iconSearch, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Search places',
                hintStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 20 / 16,
                  letterSpacing: -0.32,
                  color: Color(0xFFB9B9C6),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 20 / 16,
                letterSpacing: -0.32,
                color: AppColors.deepRoast,
              ),
            ),
          ),
        ],
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
                    Text(category.emoji),
                    const SizedBox(width: 10),
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
    return const Row(
      children: [
        AppIcon(AssetPaths.iconLocationOutlined, size: 24),
        SizedBox(width: 8),
        Text(
          'Nearby Places',
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
    required this.onTapPlan,
  });

  final List<AddPlanPlace> plans;
  final ValueChanged<AddPlanPlace> onTapPlan;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: plans.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _NearbyPlanCard(
        plan: plans[index],
        onTap: () => onTapPlan(plans[index]),
      ),
    );
  }
}

class _NearbyPlanCard extends StatelessWidget {
  const _NearbyPlanCard({required this.plan, required this.onTap});

  final AddPlanPlace plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = plan.isHighlighted
        ? AppColors.zoviOrange
        : const Color(0xFFE2E2E2);
    final backgroundColor = plan.isHighlighted
        ? AppColors.zoviOrange.withValues(alpha: 0.10)
        : AppColors.white;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
              plan.friendsLabel,
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
  const _ContinueButton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.deepRoast,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Center(
              child: Text(
                'Continue',
                style: TextStyle(
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
    );
  }
}
