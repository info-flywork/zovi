import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/utils/extensions/future_extensions.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/profile_avatar.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/profile/edit/model/edit_profile_field_route_args.dart';
import 'package:zovi/presentation/profile/edit/model/edit_profile_field_type.dart';
import 'package:zovi/presentation/profile/edit/model/edit_profile_links_route_args.dart';
import 'package:zovi/presentation/home/view/widgets/check_in_add_photo_sheet.dart';

@immutable
final class EditProfileView extends StatefulWidget {
  const EditProfileView({required this.user, super.key});

  final UserProfile user;

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

final class _EditProfileViewState extends State<EditProfileView> {
  late String _avatarPath;
  late String _name;
  late String _username;
  late String _bio;
  late List<ProfileLink> _links;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _avatarPath = widget.user.avatarPath;
    _name = widget.user.name;
    _username = widget.user.usernameHandle;
    _bio = widget.user.bio;
    _links = List<ProfileLink>.from(widget.user.links);
  }

  Future<void> _changePhoto() async {
    final source = await showCheckInAddPhotoSheet(
      context,
      initial: CheckInPhotoSource.gallery,
    );
    if (source == null || !mounted) return;

    final imageSource = switch (source) {
      CheckInPhotoSource.camera => ImageSource.camera,
      CheckInPhotoSource.gallery => ImageSource.gallery,
    };

    final image = await _imagePicker
        .pickImage(
          source: imageSource,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
        )
        .withLoading(context);
    if (image == null || !mounted) return;
    try {
      final updated = await getIt<UserRepository>()
          .patchAvatarFile(image.path)
          .withLoading(context);
      if (!mounted) return;
      setState(() => _avatarPath = updated.avatarPath);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('error_profile_save_failed'.tr())));
    }
  }

  Future<void> _saveAndPop() async {
    final cached = getIt<UserRepository>().cachedCurrentUser;
    context.pop(
      (cached ?? widget.user).copyWith(
        name: _name.trim(),
        username: '@${_username.replaceFirst('@', '').trim()}',
        bio: _bio,
        avatarPath: _avatarPath,
        links: _links,
      ),
    );
  }

  Future<void> _editLinks() async {
    final result = await context.push<List<ProfileLink>>(
      RoutePaths.editProfileLinks.path,
      extra: EditProfileLinksRouteArgs(links: _links),
    );

    if (result == null || !mounted) return;
    setState(() => _links = result);
  }

  Future<void> _editField(EditProfileFieldType field) async {
    final initialValue = switch (field) {
      EditProfileFieldType.name => _name,
      EditProfileFieldType.username => _username,
      EditProfileFieldType.bio => _bio,
    };

    final result = await context.push<String>(
      RoutePaths.editProfileField.path,
      extra: EditProfileFieldRouteArgs(
        field: field,
        initialValue: initialValue,
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      switch (field) {
        case EditProfileFieldType.name:
          _name = result;
        case EditProfileFieldType.username:
          _username = result.replaceFirst('@', '');
        case EditProfileFieldType.bio:
          _bio = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _EditProfileHeader(onBack: _saveAndPop),
            Expanded(
              child: ListView(
                physics: ClampingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  const SizedBox(height: 32),
                  Center(child: ProfileAvatar(path: _avatarPath, size: 120)),
                  const SizedBox(height: 12),
                  Center(
                    child: GestureDetector(
                      onTap: _changePhoto,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Text(
                          'change_photo'.tr(),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 20 / 15,
                            letterSpacing: -0.375,
                            color: AppColors.accentBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _EditProfileRow(
                    label: 'name'.tr(),
                    value: _name,
                    onTap: () => _editField(EditProfileFieldType.name),
                  ),
                  _EditProfileRow(
                    label: 'username'.tr(),
                    value: _username,
                    onTap: () => _editField(EditProfileFieldType.username),
                  ),
                  _EditProfileRow(
                    label: 'bio'.tr(),
                    value: _bio,
                    onTap: () => _editField(EditProfileFieldType.bio),
                  ),
                  _EditProfileLinksRow(links: _links, onTap: _editLinks),
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
final class _EditProfileHeader extends StatelessWidget {
  const _EditProfileHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
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
            'edit_profile_title'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1,
              letterSpacing: -0.32,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
final class _EditProfileRow extends StatelessWidget {
  const _EditProfileRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 18 / 16,
                letterSpacing: -0.32,
                color: AppColors.deepRoast,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
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
    );
  }
}

@immutable
final class _EditProfileLinksRow extends StatelessWidget {
  const _EditProfileLinksRow({required this.links, required this.onTap});

  final List<ProfileLink> links;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final firstLink = links.isNotEmpty ? links.first : null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderDivider)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'links'.tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 18 / 16,
                letterSpacing: -0.32,
                color: AppColors.deepRoast,
              ),
            ),
            const Spacer(),
            if (firstLink != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    firstLink.title,
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
                    firstLink.displayUrl,
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
          ],
        ),
      ),
    );
  }
}
