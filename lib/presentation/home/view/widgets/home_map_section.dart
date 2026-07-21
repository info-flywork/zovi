part of '../home_view.dart';

class HomeMapSection extends StatelessWidget {
  const HomeMapSection({
    required this.city,
    required this.mapFriends,
    required this.onAddTap,
    super.key,
  });

  final String city;
  final List<MapFriend> mapFriends;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.asset(
            AssetPaths.mapLa,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.zoviOrange,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          AssetPaths.avatarYou,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      city,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const AppIcon(AssetPaths.iconSettings, size: 24),
              ),
            ],
          ),
        ),
        ...mapFriends.map(
          (friend) => Align(
            alignment: Alignment(friend.x, friend.y),
            child: HomeMapMarker(friend: friend),
          ),
        ),
        Align(
          alignment: const Alignment(0, 0.35),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.zoviOrange, width: 3),
            ),
            child: ClipOval(
              child: Image.asset(AssetPaths.avatarYou, fit: BoxFit.cover),
            ),
          ),
        ),
        Positioned(
          left: 20,
          bottom: 100,
          child: _RoundAction(
            color: AppColors.white,
            onTap: () {},
            child: const AppIcon(AssetPaths.iconNavigate, size: 24),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 96,
          child: _RoundAction(
            color: AppColors.zoviOrange,
            size: 60,
            onTap: onAddTap,
            child: const AppIcon(
              AssetPaths.iconAdd,
              size: 36,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.color,
    required this.child,
    required this.onTap,
    this.size = 52,
  });

  final Color color;
  final Widget child;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: child),
        ),
      ),
    );
  }
}
