import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/domain/user/user_repository.dart';

class AddProfileLinkView extends StatefulWidget {
  const AddProfileLinkView({super.key});

  @override
  State<AddProfileLinkView> createState() => _AddProfileLinkViewState();
}

class _AddProfileLinkViewState extends State<AddProfileLinkView> {
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _onDone() {
    final url = _urlController.text.trim();
    final title = _titleController.text.trim();
    if (url.isEmpty || title.isEmpty) return;

    final normalizedUrl = url.startsWith('http') ? url : 'https://$url';
    context.pop(ProfileLink(title: title, url: normalizedUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AddLinkHeader(
              onBack: () => context.pop(),
              onDone: _onDone,
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.borderDivider),
                ),
              ),
              child: TextField(
                controller: _urlController,
                autofocus: true,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'link_url_hint'.tr(),
                  hintStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 18 / 16,
                    letterSpacing: -0.32,
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 18 / 16,
                  letterSpacing: -0.32,
                  color: AppColors.deepRoast,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.borderDivider),
                ),
              ),
              child: TextField(
                controller: _titleController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _onDone(),
                decoration: InputDecoration(
                  hintText: 'link_title_hint'.tr(),
                  hintStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 18 / 16,
                    letterSpacing: -0.32,
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 18 / 16,
                  letterSpacing: -0.32,
                  color: AppColors.deepRoast,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddLinkHeader extends StatelessWidget {
  const _AddLinkHeader({
    required this.onBack,
    required this.onDone,
  });

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
              'add_link'.tr(),
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
