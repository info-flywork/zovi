part of '../profile_view.dart';

class ProfileStats extends StatelessWidget {
  const ProfileStats({required this.user, super.key});

  final UserProfile user;

  void _openConnections(BuildContext context, ProfileConnectionsTab tab) {
    final userId = getIt<AuthRepository>().backendUserId?.trim() ?? '';
    final bloc = context.read<ProfileBloc>();
    context
        .push(
          RoutePaths.profileConnections.path,
          extra: ProfileConnectionsRouteArgs(
            name: user.name,
            userId: userId,
            followersCount: user.followers,
            friendsCount: user.friends,
            isOwnProfile: true,
            initialTab: tab,
          ),
        )
        .then((_) => bloc.add(const ProfileRefreshRequested()));
  }

  @override
  Widget build(BuildContext context) {
    Widget card({
      required String value,
      required String label,
      VoidCallback? onTap,
    }) {
      final child = Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1,
                letterSpacing: -0.48,
                color: AppColors.deepRoast,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1,
                letterSpacing: -0.28,
                color: Color(0x73000000),
              ),
            ),
          ],
        ),
      );

      if (onTap == null) return Expanded(child: child);
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: child,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          card(value: '${user.checkIns}', label: 'stat_check_in'.tr()),
          const SizedBox(width: 10),
          card(
            value: '${user.followers}',
            label: 'stat_follower'.tr(),
            onTap: () =>
                _openConnections(context, ProfileConnectionsTab.followers),
          ),
          const SizedBox(width: 10),
          card(
            value: '${user.friends}',
            label: 'stat_friends'.tr(),
            onTap: () =>
                _openConnections(context, ProfileConnectionsTab.friends),
          ),
        ],
      ),
    );
  }
}
