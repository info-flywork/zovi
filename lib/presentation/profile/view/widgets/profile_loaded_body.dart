part of '../profile_view.dart';

class ProfileLoadedBody extends StatelessWidget {
  const ProfileLoadedBody({
    required this.user,
    required this.checkIns,
    required this.pulses,
    required this.stamps,
    required this.plans,
    required this.tabController,
    required this.onTabSelected,
    super.key,
  });

  final UserProfile user;
  final List<CheckInItem> checkIns;
  final List<PulseItem> pulses;
  final List<StampItem> stamps;
  final List<PlanItem> plans;
  final TabController tabController;
  final ValueChanged<ProfileContentTab> onTabSelected;

  static double _tabHeight({
    required int index,
    required double width,
    required int stampCount,
    required int checkInCount,
  }) {
    switch (index) {
      case 0:
        return 216;
      case 1:
        const spacing = 10.0;
        final itemWidth = (width - 32 - spacing * 2) / 3;
        final cardHeight = itemWidth + 20;
        final rows = (stampCount / 3).ceil().clamp(1, 100);
        return 16 + rows * cardHeight + (rows - 1) * spacing;
      case 2:
      default:
        return 16 + checkInCount * 80.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.only(
        bottom:
            MainWrapper.navBarHeight + MediaQuery.paddingOf(context).bottom + 16,
      ),
      children: [
        ProfileHeader(
          user: user,
          onShareTap: () =>
              ProfileShareSheet.show(context, username: user.username),
        ),
        ProfileStats(user: user),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppIcon(AssetPaths.iconLocationDark, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    user.location,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1,
                      letterSpacing: -0.28,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                user.bio,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.32,
                  color: AppColors.deepRoast,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ProfileActionButton(
                      label: 'edit_profile'.tr(),
                      backgroundColor: AppColors.zoviOrange,
                      foregroundColor: AppColors.white,
                      onTap: () async {
                        final updatedUser = await context.push<UserProfile>(
                          RoutePaths.editProfile.path,
                          extra: EditProfileRouteArgs(user: user),
                        );
                        if (updatedUser == null || !context.mounted) return;
                        context.read<ProfileBloc>().add(
                          ProfileUserUpdated(updatedUser),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ProfileActionButton(
                      label: 'share_profile'.tr(),
                      backgroundColor: AppColors.surfaceGray,
                      foregroundColor: AppColors.mutedGray,
                      onTap: () => ProfileShareSheet.show(
                        context,
                        username: user.username,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ProfileMap(location: user.location),
        const SizedBox(height: 16),
        ProfilePlans(plans: plans),
        const SizedBox(height: 16),
        ProfileTabs(
          controller: tabController,
          onTabSelected: onTabSelected,
        ),
        AnimatedBuilder(
          animation: tabController.animation!,
          builder: (context, child) {
            final value = tabController.animation!.value.clamp(0.0, 2.0);
            final lower = value.floor().clamp(0, 2);
            final upper = value.ceil().clamp(0, 2);
            final t = value - lower;
            final height = lerpDouble(
              _tabHeight(
                index: lower,
                width: width,
                stampCount: stamps.length,
                checkInCount: checkIns.length,
              ),
              _tabHeight(
                index: upper,
                width: width,
                stampCount: stamps.length,
                checkInCount: checkIns.length,
              ),
              t,
            )!;
            return SizedBox(height: height, child: child);
          },
          child: TabBarView(
            controller: tabController,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ProfilePulses(pulses: pulses),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ProfileStamps(stamps: stamps),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ProfileCheckins(checkIns: checkIns),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: foregroundColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            height: 1,
            letterSpacing: -0.32,
          ),
        ),
      ),
    );
  }
}
