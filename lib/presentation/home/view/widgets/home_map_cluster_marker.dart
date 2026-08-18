part of '../home_view.dart';

/// Üst üste binen pin’ler için yığılmış avatar + sayı rozeti.
@immutable
final class HomeMapClusterMarker extends StatelessWidget {
  const HomeMapClusterMarker({
    required this.avatarPaths,
    required this.count,
    super.key,
  });

  final List<String> avatarPaths;
  final int count;

  static const size = 64.0;
  static const width = 88.0;
  static const height = 76.0;

  @override
  Widget build(BuildContext context) {
    final paths = avatarPaths.take(3).toList(growable: false);
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < paths.length; i++)
            Positioned(
              left: 8.0 + i * 14,
              top: 4,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ProfileAvatar(path: paths[i], size: 43),
              ),
            ),
          Positioned(
            right: 0,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.zoviOrange,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
