part of '../profile_view.dart';

class ProfileLoadedBody extends StatelessWidget {
  const ProfileLoadedBody({
    required this.user,
    required this.checkIns,
    required this.pulses,
    required this.stamps,
    required this.plans,
    required this.selectedTab,
    required this.onTabSelected,
    super.key,
  });

  final UserProfile user;
  final List<CheckInItem> checkIns;
  final List<PulseItem> pulses;
  final List<StampItem> stamps;
  final List<PlanItem> plans;
  final ProfileContentTab selectedTab;
  final ValueChanged<ProfileContentTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
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
        ProfileTabs(selectedTab: selectedTab, onTabSelected: onTabSelected),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [...previousChildren, ?currentChild],
              );
            },
            transitionBuilder: (child, animation) {
              final offset = Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offset, child: child),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(selectedTab),
              child: switch (selectedTab) {
                ProfileContentTab.pulse => ProfilePulses(pulses: pulses),
                ProfileContentTab.stamps => ProfileStamps(stamps: stamps),
                ProfileContentTab.checkIn => ProfileCheckins(
                  checkIns: checkIns,
                ),
              },
            ),
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
