import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/domain/user/user_repository.dart';

Future<void> showProfileLinksSheet(
  BuildContext context, {
  required List<ProfileLink> links,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ProfileLinksSheet(links: links),
  );
}

Future<void> openProfileLink(String rawUrl) async {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return;
  final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
  final uri = Uri.tryParse(withScheme);
  if (uri == null) return;
  final launched = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );
  if (!launched) {
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }
}

@immutable
final class _ProfileLinksSheet extends StatelessWidget {
  const _ProfileLinksSheet({required this.links});

  final List<ProfileLink> links;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'links'.tr(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1,
              letterSpacing: -0.28,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < links.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _ProfileLinkSheetRow(link: links[i]),
          ],
        ],
      ),
    );
  }
}

@immutable
final class _ProfileLinkSheetRow extends StatelessWidget {
  const _ProfileLinkSheetRow({required this.link});

  final ProfileLink link;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openProfileLink(link.url),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FCFF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                link.url,
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
            const SizedBox(width: 8),
            const AppIcon(AssetPaths.iconLink, size: 24),
          ],
        ),
      ),
    );
  }
}
