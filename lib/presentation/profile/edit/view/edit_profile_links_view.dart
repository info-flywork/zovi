import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/snackbar/app_snackbar.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/utils/extensions/future_extensions.dart';
import 'package:zovi/core/widgets/app_confirm_dialog.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/domain/user/user_repository.dart';

@immutable
final class EditProfileLinksView extends StatefulWidget {
  const EditProfileLinksView({required this.links, super.key});

  final List<ProfileLink> links;

  @override
  State<EditProfileLinksView> createState() => _EditProfileLinksViewState();
}

final class _EditProfileLinksViewState extends State<EditProfileLinksView> {
  late List<ProfileLink> _links;

  @override
  void initState() {
    super.initState();
    _links = List<ProfileLink>.from(widget.links);
  }

  Future<void> _addLink() async {
    final updatedLinks = await context.push<List<ProfileLink>>(
      RoutePaths.addProfileLink.path,
      extra: _links,
    );
    if (updatedLinks == null || !mounted) return;

    setState(() => _links = updatedLinks);
    AppSnackbar.instance.showLinkAdded(
      context,
      'link_added_snackbar'.tr(),
    );
  }

  Future<void> _removeLink(int index) async {
    if (index < 0 || index >= _links.length) return;
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'link_delete_title'.tr(),
      subtitle: 'link_delete_subtitle'.tr(),
      confirmLabel: 'link_delete_confirm'.tr(),
    );
    if (!confirmed || !mounted) return;
    setState(() => _links = [..._links]..removeAt(index));
  }

  Future<void> _onDone() async {
    if (_sameLinks(_links, widget.links)) {
      context.pop(_links);
      return;
    }
    try {
      final updated = await getIt<UserRepository>()
          .patchProfileLinks(_links)
          .withLoading(context);
      if (!mounted) return;
      context.pop(updated.links);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.instance.show(
        context,
        'error_profile_save_failed'.tr(),
        isError: true,
      );
    }
  }

  static bool _sameLinks(List<ProfileLink> a, List<ProfileLink> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].title != b[i].title || a[i].url != b[i].url) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LinksHeader(
              onBack: () => context.pop(_links),
              onDone: _onDone,
            ),
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                children: [
                  _AddLinkRow(onTap: _addLink),
                  for (var i = 0; i < _links.length; i++)
                    _LinkItemRow(
                      link: _links[i],
                      onDelete: () => _removeLink(i),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 24, 24),
                    child: Text(
                      'links_visibility'.tr(),
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

@immutable
final class _LinksHeader extends StatelessWidget {
  const _LinksHeader({required this.onBack, required this.onDone});

  final VoidCallback onBack;
  final VoidCallback onDone;

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
            Text(
              'links'.tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1,
                letterSpacing: -0.32,
                color: AppColors.black,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onDone,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  'done'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1,
                    letterSpacing: -0.32,
                    color: AppColors.doneBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
final class _AddLinkRow extends StatelessWidget {
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
            Text(
              'add_link'.tr(),
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

@immutable
final class _LinkItemRow extends StatelessWidget {
  const _LinkItemRow({required this.link, required this.onDelete});

  final ProfileLink link;
  final VoidCallback onDelete;

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
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: AppIcon(
                AssetPaths.iconTrash,
                size: 22,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
