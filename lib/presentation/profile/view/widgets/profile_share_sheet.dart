part of '../profile_view.dart';

class ProfileShareSheet extends StatelessWidget {
  const ProfileShareSheet({
    required this.profileLink,
    required this.parentContext,
    super.key,
  });

  final String profileLink;
  final BuildContext parentContext;

  static Future<void> show(BuildContext context, {required String username}) {
    final handle = username.startsWith('@') ? username.substring(1) : username;
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ProfileShareSheet(
        profileLink: 'zovi.app/$handle',
        parentContext: context,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 50),
          padding: EdgeInsets.fromLTRB(16, 50, 16, 10 + bottomInset),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Share with Friends',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1,
                  letterSpacing: -0.4,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Everything is more fun when you connect with your friends!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 20 / 16,
                  letterSpacing: -0.32,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Share the profile',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    letterSpacing: -0.28,
                    color: AppColors.black,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.shareSheetFill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        profileLink,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1,
                          letterSpacing: -0.28,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await Clipboard.setData(
                          ClipboardData(text: profileLink),
                        );
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!parentContext.mounted) return;
                          AppSnackbar.instance.show(
                            parentContext,
                            'Link copied!',
                          );
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: AppIcon(AssetPaths.iconCopy2, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          child: Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: AppColors.shareSheetFill,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(AssetPaths.chain, fit: BoxFit.contain),
            ),
          ),
        ),
        Positioned(
          top: 80,
          right: 16,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: const AppIcon(AssetPaths.iconCloseCircle, size: 32),
          ),
        ),
      ],
    );
  }
}
