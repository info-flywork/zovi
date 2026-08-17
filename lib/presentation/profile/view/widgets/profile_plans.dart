part of '../profile_view.dart';

class ProfilePlans extends StatelessWidget {
  const ProfilePlans({required this.plans, super.key});

  final List<PlanItem> plans;

  @override
  Widget build(BuildContext context) {
    final hasPlans = plans.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              AppIcon(AssetPaths.iconCalendarDate, size: 20),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'today_plans'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    letterSpacing: -0.32,
                    color: AppColors.black,
                  ),
                ),
              ),
              InkWell(
                onTap: () => context.push(RoutePaths.addPlan.path),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 24, color: AppColors.zoviOrange),
                    const SizedBox(width: 2),
                    Text(
                      'add_plan'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1,
                        letterSpacing: -0.28,
                        color: AppColors.zoviOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasPlans)
            _EmptyProfileSection(
              icon: AssetPaths.iconCalendarDate,
              text: 'empty_plans'.tr(),
            )
          else
            ...plans.map(
              (plan) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PlanCard(plan: plan),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyProfileSection extends StatelessWidget {
  const _EmptyProfileSection({
    required this.icon,
    required this.text,
  });

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 24, color: AppColors.mutedGray),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final PlanItem plan;

  @override
  Widget build(BuildContext context) {
    final hasFriends = plan.hasJoiningFriends;
    final friendsText = hasFriends
        ? 'friends_are_joining'.tr(namedArgs: {'count': plan.friendsLabel})
        : 'no_friends_joining'.tr();

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(
        children: [
          Text(
            plan.time,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1,
              letterSpacing: -0.32,
              color: AppColors.zoviOrange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  plan.placeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    letterSpacing: -0.32,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  plan.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1,
                    letterSpacing: -0.28,
                    color: AppColors.deepRoast.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (hasFriends) ...[
            OverlappingProfileAvatars(
              avatars: plan.friendAvatars,
              overlap: 12,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              friendsText,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.15,
                letterSpacing: -0.24,
                color: AppColors.deepRoast.withValues(alpha: 0.65),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

