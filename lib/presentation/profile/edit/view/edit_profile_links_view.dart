import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/snackbar/app_snackbar.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/domain/user/user_repository.dart';

class EditProfileLinksView extends StatefulWidget {
  const EditProfileLinksView({required this.links, super.key});

  final List<ProfileLink> links;

  @override
  State<EditProfileLinksView> createState() => _EditProfileLinksViewState();
}

class _EditProfileLinksViewState extends State<EditProfileLinksView> {
  late List<ProfileLink> _links;

  @override
  void initState() {
    super.initState();
    _links = List<ProfileLink>.from(widget.links);
  }

  Future<void> _addLink() async {
    final link = await context.push<ProfileLink>(
      RoutePaths.addProfileLink.path,
    );
    if (link == null || !mounted) return;

    setState(() => _links = [..._links, link]);
    AppSnackbar.instance.showLinkAdded(
      context,
      'A link has been added to your bio.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LinksHeader(onBack: () => context.pop(_links)),
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                children: [
                  _AddLinkRow(onTap: _addLink),
                  ..._links.map(_LinkItemRow.new),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(0, 16, 24, 24),
                    child: Text(
                      'Your links are visible to everyone on and off Zovi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 18 / 16,
                        letterSpacing: -0.32,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinksHeader extends StatelessWidget {
  const _LinksHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: const AppIcon(AssetPaths.iconBack, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Links',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1,
                letterSpacing: -0.32,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddLinkRow extends StatelessWidget {
  const _AddLinkRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderDivider)),
        ),
        child: Row(
          children: [
            const AppIcon(AssetPaths.iconAddCircleOutline, size: 24),
            const SizedBox(width: 12),
            const Text(
              'Add link',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 18 / 16,
                letterSpacing: -0.32,
                color: AppColors.deepRoast,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkItemRow extends StatelessWidget {
  const _LinkItemRow(this.link);

  final ProfileLink link;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderDivider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const AppIcon(AssetPaths.iconLink, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  link.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 18 / 16,
                    letterSpacing: -0.32,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  link.displayUrl,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 18 / 16,
                    letterSpacing: -0.32,
                    color: AppColors.textSecondary,
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
