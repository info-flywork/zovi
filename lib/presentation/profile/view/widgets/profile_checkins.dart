part of '../profile_view.dart';

class ProfileCheckins extends StatelessWidget {
  const ProfileCheckins({required this.checkIns, super.key});

  final List<CheckInItem> checkIns;

  @override
  Widget build(BuildContext context) {
    if (checkIns.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: _EmptyCheckinsState(text: 'empty_checkins'.tr()),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          for (final item in checkIns)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGray),
              ),
              child: Row(
                children: [
                  _CheckInThumb(item: item),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.placeName,
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
                          item.when,
                          style: const TextStyle(
                            fontFamily: 'SF Pro',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
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
            ),
        ],
      ),
    );
  }
}

class _CheckInThumb extends StatelessWidget {
  const _CheckInThumb({required this.item});

  final CheckInItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: item.accentColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: item.hasPhoto
            ? (item.isNetwork
                  ? Image.network(
                      item.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Image.asset(
                        AssetPaths.checkinPlace,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(item.imagePath, fit: BoxFit.cover))
            : Image.asset(AssetPaths.checkinPlace, fit: BoxFit.cover),
      ),
    );
  }
}

class _EmptyCheckinsState extends StatelessWidget {
  const _EmptyCheckinsState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surfaceGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            AssetPaths.iconLocationOutlined,
            size: 26,
            color: AppColors.mutedGray,
          ),
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
