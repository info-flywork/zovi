part of '../profile_view.dart';

class ProfileStats extends StatelessWidget {
  const ProfileStats({required this.user, super.key});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    Widget card(String value, String label) {
      return Expanded(
        child: Container(
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
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          card('${user.checkIns}', 'stat_check_in'.tr()),
          const SizedBox(width: 10),
          card('${user.followers}', 'stat_follower'.tr()),
          const SizedBox(width: 10),
          card('${user.friends}', 'stat_friends'.tr()),
        ],
      ),
    );
  }
}
