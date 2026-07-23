part of '../profile_view.dart';

class ProfileTabs extends StatelessWidget {
  const ProfileTabs({
    required this.controller,
    required this.onTabSelected,
    super.key,
  });

  final TabController controller;
  final ValueChanged<ProfileContentTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedBuilder(
        animation: controller.animation!,
        builder: (context, _) {
          final progress = controller.animation!.value.clamp(0.0, 2.0);
          return LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / 3;
              return Stack(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < 3; i++)
                        Expanded(
                          child: _TabItem(
                            label: switch (ProfileContentTab.values[i]) {
                              ProfileContentTab.pulse => 'tab_pulse'.tr(),
                              ProfileContentTab.stamps => 'tab_stamps'.tr(),
                              ProfileContentTab.checkIn => 'tab_check_in'.tr(),
                            },
                            selectedAmount: (1.0 - (progress - i).abs())
                                .clamp(0.0, 1.0),
                            onTap: () =>
                                onTabSelected(ProfileContentTab.values[i]),
                          ),
                        ),
                    ],
                  ),
                  Positioned(
                    left: progress * tabWidth,
                    bottom: 0,
                    width: tabWidth,
                    child: const ColoredBox(
                      color: AppColors.zoviOrange,
                      child: SizedBox(height: 2),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.selectedAmount,
    required this.onTap,
  });

  final String label;
  final double selectedAmount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(
      AppColors.textTertiary,
      AppColors.zoviOrange,
      selectedAmount,
    )!;
    final weight = FontWeight.lerp(
      FontWeight.w400,
      FontWeight.w500,
      selectedAmount,
    )!;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: weight,
            height: 1,
            letterSpacing: -0.32,
            color: color,
          ),
        ),
      ),
    );
  }
}
