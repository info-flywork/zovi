part of '../home_view.dart';

@immutable
final class HomeMapVenueSheet extends StatelessWidget {
  const HomeMapVenueSheet({
    required this.venue,
    required this.onClose,
    this.photoPath,
    super.key,
  });

  final MapVenue venue;
  final String? photoPath;
  final VoidCallback onClose;

  static const _thumbSize = 68.0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: onClose,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              _VenueThumb(photoPath: photoPath),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      venue.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 18 / 16,
                        color: AppColors.black,
                      ),
                    ),
                    if (venue.peopleCount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'map_venue_people'.tr(
                          namedArgs: {'count': '${venue.peopleCount}'},
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 18 / 14,
                          color: AppColors.zoviOrange,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      'Kapatmak için dokun',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1,
                        color: AppColors.deepRoast.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
final class _VenueThumb extends StatelessWidget {
  const _VenueThumb({this.photoPath});

  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    final path = (photoPath ?? '').trim();
    final hasPhoto = path.isNotEmpty;
    final isNetwork = path.startsWith('http://') || path.startsWith('https://');
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: HomeMapVenueSheet._thumbSize,
        height: HomeMapVenueSheet._thumbSize,
        color: AppColors.deepRoast.withValues(alpha: 0.06),
        child: hasPhoto
            ? (isNetwork
                  ? Image.network(
                      path,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _VenueThumbFallback(),
                    )
                  : Image.asset(
                      path,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _VenueThumbFallback(),
                    ))
            : const _VenueThumbFallback(),
      ),
    );
  }
}

@immutable
final class _VenueThumbFallback extends StatelessWidget {
  const _VenueThumbFallback();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: const AppIcon(
          AssetPaths.iconLocationOutlined,
          size: 20,
          color: AppColors.zoviOrange,
        ),
      ),
    );
  }
}
