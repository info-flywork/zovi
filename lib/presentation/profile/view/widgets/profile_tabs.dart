part of '../profile_view.dart';

class ProfileTabs extends StatelessWidget {
  const ProfileTabs({
    required this.selectedTab,
    required this.onTabSelected,
    super.key,
  });

  final ProfileContentTab selectedTab;
  final ValueChanged<ProfileContentTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _TabItem(
            label: 'tab_pulse'.tr(),
            selected: selectedTab == ProfileContentTab.pulse,
            onTap: () => onTabSelected(ProfileContentTab.pulse),
          ),
          _TabItem(
            label: 'tab_stamps'.tr(),
            selected: selectedTab == ProfileContentTab.stamps,
            onTap: () => onTabSelected(ProfileContentTab.stamps),
          ),
          _TabItem(
            label: 'tab_check_in'.tr(),
            selected: selectedTab == ProfileContentTab.checkIn,
            onTap: () => onTabSelected(ProfileContentTab.checkIn),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                  height: 1,
                  letterSpacing: -0.32,
                  color: selected
                      ? AppColors.zoviOrange
                      : AppColors.textTertiary,
                ),
                child: Text(label),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: 2,
              width: double.infinity,
              color: selected ? AppColors.zoviOrange : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}
