part of '../profile_view.dart';

class ProfilePlans extends StatelessWidget {
  const ProfilePlans({required this.plans, super.key});

  final List<PlanItem> plans;

  static String _localizedFriendsLabel(String friendsLabel) {
    final match = RegExp(r'^(\d+)').firstMatch(friendsLabel.trim());
    if (match != null) {
      final count = int.tryParse(match.group(1)!) ?? 0;
      if (count <= 0) return 'no_friends_joining'.tr();
      return 'friends_are_joining'.tr(namedArgs: {'count': match.group(1)!});
    }
    return friendsLabel;
  }

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
    final countMatch =
        RegExp(r'^(\d+)').firstMatch(plan.friendsLabel.trim());
    final joiningCount =
        int.tryParse(countMatch?.group(1) ?? '') ??
        (plan.friendAvatars.isNotEmpty ? plan.friendAvatars.length : 0);
    final hasJoiningFriends = joiningCount > 0;

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
          if (hasJoiningFriends && plan.friendAvatars.isNotEmpty) ...[
            _OverlappingAvatars(avatars: plan.friendAvatars),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              ProfilePlans._localizedFriendsLabel(plan.friendsLabel),
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

class _OverlappingAvatars extends StatelessWidget {
  const _OverlappingAvatars({required this.avatars});

  final List<String> avatars;

  @override
  Widget build(BuildContext context) {
    const size = 34.0;
    const overlap = 12.0;
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
