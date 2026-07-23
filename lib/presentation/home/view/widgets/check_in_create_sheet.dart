import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zovi/core/snackbar/app_snackbar.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/utils/extensions/future_extensions.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/presentation/home/model/check_in_success_route_args.dart';
import 'package:zovi/presentation/home/view/widgets/check_in_add_friends_sheet.dart';
import 'package:zovi/presentation/home/view/widgets/check_in_add_photo_sheet.dart';
import 'package:zovi/presentation/profile/settings/view/widgets/account_privacy_sheet.dart';

Future<void> showCheckInCreateSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: AppColors.white,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const CheckInCreateSheet(),
  );
}

class CheckInCreateSheet extends StatefulWidget {
  const CheckInCreateSheet({super.key});

  @override
  State<CheckInCreateSheet> createState() => _CheckInCreateSheetState();
}

class _CheckInCreateSheetState extends State<CheckInCreateSheet> {
  static const _maxLength = 160;
  static const _friendAnimDuration = Duration(milliseconds: 280);
  static const _photoAnimDuration = Duration(milliseconds: 280);
  static const _fallbackCenter = LatLng(41.0584, 28.9857);
  static const _defaultZoom = 15.0;
  static const _tileUrl =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
  static const _tileSubdomains = ['a', 'b', 'c', 'd'];

  final _controller = TextEditingController();
  final _mapController = MapController();
  final _imagePicker = ImagePicker();
  final _friendsListKey = GlobalKey<AnimatedListState>();
  final _photosListKey = GlobalKey<AnimatedListState>();
  AccountPrivacy _photoPrivacy = AccountPrivacy.public;
  CheckInPhotoSource _photoSource = CheckInPhotoSource.camera;
  LatLng _center = _fallbackCenter;
  final List<CheckInFriend> _taggedFriends = [];
  final List<String> _photoPaths = [];
  var _photosRowVisible = false;

  @override
  void initState() {
    super.initState();
    _resolveLocation();
  }

  @override
  void dispose() {
    _controller.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _resolveLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }
      if (position == null || !mounted) return;

      final target = LatLng(position.latitude, position.longitude);
      setState(() => _center = target);
      _mapController.move(target, _defaultZoom);
    } catch (_) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last == null || !mounted) return;
        final target = LatLng(last.latitude, last.longitude);
        setState(() => _center = target);
        _mapController.move(target, _defaultZoom);
      } catch (_) {}
    }
  }

  Future<void> _openPhotoPrivacy() async {
    final selected = await showAccountPrivacySheet(
      context,
      initial: _photoPrivacy,
      useRootNavigator: true,
      titleKey: 'photo_privacy_sheet_title',
      subtitleKey: 'photo_privacy_sheet_subtitle',
      publicSubtitleKey: 'photo_privacy_public_subtitle',
      friendsSubtitleKey: 'photo_privacy_friends_subtitle',
    );
    if (selected == null || !mounted) return;
    setState(() => _photoPrivacy = selected);
  }

  Future<void> _openAddPhoto() async {
    final selected = await showCheckInAddPhotoSheet(
      context,
      initial: _photoSource,
    );
    if (selected == null || !mounted) return;
    setState(() => _photoSource = selected);

    try {
      if (selected == CheckInPhotoSource.camera) {
        final image = await _pickCameraFlow().withLoading(context);
        if (!mounted || image == null) return;
        await _addPhotos([image.path]);
      } else {
        final images = await _pickGalleryFlow().withLoading(context);
        if (!mounted || images.isEmpty) return;
        await _addPhotos(images.map((e) => e.path).toList());
      }
    } on _CheckInPhotoPermissionDeniedException {
      if (!mounted) return;
      AppSnackbar.instance.show(
        context,
        'chat_permission_denied'.tr(),
        isError: true,
      );
    }
  }

  Future<XFile?> _pickCameraFlow() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      throw const _CheckInPhotoPermissionDeniedException();
    }
    return _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 85);
  }

  Future<List<XFile>> _pickGalleryFlow() {
    return _imagePicker.pickMultiImage(imageQuality: 85);
  }

  Future<void> _addPhotos(List<String> paths) async {
    if (paths.isEmpty) return;

    if (!_photosRowVisible) {
      setState(() => _photosRowVisible = true);
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
    }

    for (final path in paths) {
      final index = _photoPaths.length;
      _photoPaths.add(path);
      _photosListKey.currentState?.insertItem(
        index,
        duration: _photoAnimDuration,
      );
    }
    setState(() {});
  }

  void _removePhoto(String path) {
    final index = _photoPaths.indexOf(path);
    if (index < 0) return;
    _removePhotoAt(index);
  }

  void _removePhotoAt(int index) {
    if (index < 0 || index >= _photoPaths.length) return;
    final removed = _photoPaths.removeAt(index);
    _photosListKey.currentState?.removeItem(
      index,
      (context, animation) =>
          _CheckInPhotoThumb(path: removed, animation: animation),
      duration: _photoAnimDuration,
    );

    if (_photoPaths.isEmpty) {
      Future<void>.delayed(_photoAnimDuration, () {
        if (!mounted || _photoPaths.isNotEmpty) return;
        setState(() => _photosRowVisible = false);
      });
    } else {
      setState(() {});
    }
  }

  Future<void> _openAddFriends() async {
    final selected = await showCheckInAddFriendsSheet(
      context,
      initiallySelected: List<CheckInFriend>.from(_taggedFriends),
    );
    if (selected == null || !mounted) return;
    _syncTaggedFriends(selected);
  }

  void _syncTaggedFriends(List<CheckInFriend> next) {
    final nextIds = next.map((f) => f.id).toSet();

    for (var i = _taggedFriends.length - 1; i >= 0; i--) {
      if (!nextIds.contains(_taggedFriends[i].id)) {
        _removeFriendAt(i);
      }
    }

    for (final friend in next) {
      if (_taggedFriends.any((f) => f.id == friend.id)) continue;
      final index = _taggedFriends.length;
      _taggedFriends.add(friend);
      _friendsListKey.currentState?.insertItem(
        index + 1,
        duration: _friendAnimDuration,
      );
    }

    setState(() {});
  }

  void _removeFriend(CheckInFriend friend) {
    final index = _taggedFriends.indexWhere((f) => f.id == friend.id);
    if (index < 0) return;
    _removeFriendAt(index);
    setState(() {});
  }

  void _submitCheckIn() {
    final router = GoRouter.of(context);
    final args = CheckInSuccessRouteArgs(
      placeName: 'check_in_venue_demo'.tr(),
      friendNames: _taggedFriends.map((f) => f.name).toList(),
      hasPhoto: _photoPaths.isNotEmpty,
      photoPaths: List<String>.from(_photoPaths),
    );
    Navigator.of(context).pop();
    router.push(RoutePaths.checkInSuccess.path, extra: args);
  }

  void _removeFriendAt(int index) {
    final removed = _taggedFriends.removeAt(index);
    _friendsListKey.currentState?.removeItem(
      index + 1,
      (context, animation) =>
          _TaggedFriendChip(friend: removed, animation: animation),
      duration: _friendAnimDuration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final privacyLabel = _photoPrivacy == AccountPrivacy.public
        ? 'privacy_public'.tr()
        : 'privacy_friends'.tr();
    final privacyIcon = _photoPrivacy == AccountPrivacy.public
        ? AssetPaths.iconPublic
        : AssetPaths.iconFriends;

    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.88;
    const headerHeight = 78.0;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: Material(
            color: AppColors.white,
            child: SafeArea(
              top: false,
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 46,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Row(
                      children: [
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          behavior: HitTestBehavior.opaque,
                          child: const AppIcon(AssetPaths.iconCloseCircle),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: maxSheetHeight - headerHeight,
                    ),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: double.infinity,
                              height: 200,
                              child: IgnorePointer(
                                child: FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter: _center,
                                    initialZoom: _defaultZoom,
                                    backgroundColor: AppColors.offWhite,
                                    interactionOptions:
                                        const InteractionOptions(
                                          flags: InteractiveFlag.none,
                                        ),
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate: _tileUrl,
                                      subdomains: _tileSubdomains,
                                      userAgentPackageName: 'com.flywork.zovi',
                                      maxZoom: 20,
                                      retinaMode: RetinaMode.isHighDensity(
                                        context,
                                      ),
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: _center,
                                          width: 55,
                                          height: 69,
                                          alignment: Alignment.center,
                                          child: const _CheckInLocationPin(
                                            avatarPath: AssetPaths.avatarYou,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'check_in_venue_demo'.tr(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              height: 1,
                              letterSpacing: -0.4,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {},
                            behavior: HitTestBehavior.opaque,
                            child: Text(
                              'check_in_change_location'.tr(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 20 / 14,
                                letterSpacing: -0.28,
                                color: AppColors.chatPurple,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            height: 104,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.black.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    maxLength: _maxLength,
                                    maxLines: null,
                                    expands: true,
                                    textAlignVertical: TextAlignVertical.top,
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      height: 20 / 16,
                                      letterSpacing: -0.32,
                                      color: AppColors.black,
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      counterText: '',
                                      border: InputBorder.none,
                                      hintText: 'check_in_prompt'.tr(),
                                      hintStyle: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        height: 20 / 14,
                                        letterSpacing: -0.28,
                                        color: AppColors.deepRoast.withValues(
                                          alpha: 0.35,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '${_controller.text.characters.length}/$_maxLength',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      height: 20 / 14,
                                      letterSpacing: -0.28,
                                      color: AppColors.black.withValues(
                                        alpha: 0.35,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _openAddPhoto,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: double.infinity,
                              height: 44,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.mintGreen.withValues(
                                  alpha: 0.10,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const AppIcon(
                                    AssetPaths.iconAdd2,
                                    size: 20,
                                    color: AppColors.mintGreen,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'check_in_add_photo'.tr(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      height: 20 / 14,
                                      letterSpacing: -0.28,
                                      color: AppColors.mintGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AnimatedSize(
                            duration: _photoAnimDuration,
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topCenter,
                            child: !_photosRowVisible
                                ? const SizedBox(width: double.infinity)
                                : Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        const sideInset = 16.0;
                                        final listWidth =
                                            constraints.maxWidth +
                                            sideInset * 2;
                                        return SizedBox(
                                          height: 140,
                                          width: constraints.maxWidth,
                                          child: OverflowBox(
                                            alignment: Alignment.center,
                                            minWidth: listWidth,
                                            maxWidth: listWidth,
                                            child: SizedBox(
                                              width: listWidth,
                                              height: 140,
                                              child: AnimatedList(
                                                key: _photosListKey,
                                                scrollDirection:
                                                    Axis.horizontal,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                    ),
                                                initialItemCount:
                                                    _photoPaths.length,
                                                itemBuilder:
                                                    (
                                                      context,
                                                      index,
                                                      animation,
                                                    ) {
                                                      final path =
                                                          _photoPaths[index];
                                                      return _CheckInPhotoThumb(
                                                        path: path,
                                                        animation: animation,
                                                        onRemove: () =>
                                                            _removePhoto(path),
                                                      );
                                                    },
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'check_in_with'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                height: 20 / 16,
                                letterSpacing: -0.32,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              const sideInset = 16.0;
                              final listWidth =
                                  constraints.maxWidth + sideInset * 2;
                              return SizedBox(
                                height: 37,
                                width: constraints.maxWidth,
                                child: OverflowBox(
                                  alignment: Alignment.center,
                                  minWidth: listWidth,
                                  maxWidth: listWidth,
                                  child: SizedBox(
                                    width: listWidth,
                                    height: 37,
                                    child: AnimatedList(
                                      key: _friendsListKey,
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      initialItemCount:
                                          _taggedFriends.length + 1,
                                      itemBuilder: (context, index, animation) {
                                        if (index == 0) {
                                          return _AddFriendsChip(
                                            onTap: _openAddFriends,
                                          );
                                        }
                                        final friend =
                                            _taggedFriends[index - 1];
                                        return _TaggedFriendChip(
                                          friend: friend,
                                          animation: animation,
                                          onRemove: () => _removeFriend(friend),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          GestureDetector(
                            onTap: _openPhotoPrivacy,
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: [
                                Text(
                                  'check_in_photo_privacy'.tr(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    height: 20 / 16,
                                    letterSpacing: -0.32,
                                    color: AppColors.black,
                                  ),
                                ),
                                const Spacer(),
                                AppIcon(privacyIcon),
                                const SizedBox(width: 6),
                                Text(
                                  privacyLabel,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 20 / 14,
                                    letterSpacing: -0.28,
                                    color: AppColors.black,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const AppIcon(
                                  AssetPaths.iconRight,
                                  size: 16,
                                  color: AppColors.black,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: Material(
                              color: AppColors.zoviOrange,
                              shape: const StadiumBorder(),
                              child: InkWell(
                                onTap: _submitCheckIn,
                                customBorder: const StadiumBorder(),
                                child: Center(
                                  child: Text(
                                    'check_in_submit'.tr(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      height: 20 / 16,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckInPhotoPermissionDeniedException implements Exception {
  const _CheckInPhotoPermissionDeniedException();
}

class _CheckInPhotoThumb extends StatelessWidget {
  const _CheckInPhotoThumb({
    required this.path,
    required this.animation,
    this.onRemove,
  });

  final String path;
  final Animation<double> animation;
  final VoidCallback? onRemove;

  static const _width = 125.0;
  static const _height = 127.0;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return SizeTransition(
      sizeFactor: curved,
      axis: Axis.horizontal,
      alignment: Alignment.centerLeft,
      child: FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1).animate(curved),
          child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: SizedBox(
              width: _width,
              height: _height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(File(path), fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onRemove,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.mutedGray,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddFriendsChip extends StatelessWidget {
  const _AddFriendsChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F9),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 29,
                height: 29,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const AppIcon(AssetPaths.iconAddUser),
              ),
              const SizedBox(width: 8),
              Text(
                'check_in_add_friends'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 20 / 14,
                  letterSpacing: -0.28,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaggedFriendChip extends StatelessWidget {
  const _TaggedFriendChip({
    required this.friend,
    required this.animation,
    this.onRemove,
  });

  final CheckInFriend friend;
  final Animation<double> animation;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return SizeTransition(
      sizeFactor: curved,
      axis: Axis.horizontal,
      alignment: Alignment.centerLeft,
      child: FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.86, end: 1).animate(curved),
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 29,
                    height: 29,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2),
                      image: DecorationImage(
                        image: AssetImage(friend.avatarPath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    friend.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 20 / 14,
                      letterSpacing: -0.28,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onRemove,
                    behavior: HitTestBehavior.opaque,
                    child: const Icon(
                      Icons.close,
                      color: AppColors.mutedGray,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckInLocationPin extends StatelessWidget {
  const _CheckInLocationPin({required this.avatarPath});

  final String avatarPath;

  static const _width = 55.0;
  static const _height = 69.0;
  static const _avatarSize = 40.0;
  static const _avatarTop = 4.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      height: _height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            SvgPicture.asset(
              AssetPaths.iconLocationProfile,
              width: _width,
              height: _height,
              fit: BoxFit.fill,
            ),
            Positioned(
              top: _avatarTop,
              child: Container(
                width: _avatarSize,
                height: _avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                  image: DecorationImage(
                    image: AssetImage(avatarPath),
                    fit: BoxFit.cover,
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
