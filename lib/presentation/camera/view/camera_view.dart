import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/app_loading.dart';
import 'package:zovi/presentation/camera/model/camera_compose_route_args.dart';
import 'package:zovi/presentation/camera/view/widgets/camera_drafts_sheet.dart';

enum _CameraMode { draft, story }

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  static const _cacheFileName = 'camera_last_thumb.jpg';

  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  var _initializing = true;
  String? _error;
  var _flashOn = false;
  var _mode = _CameraMode.story;
  String? _lastPhotoPath;
  Uint8List? _thumbBytes;
  var _capturing = false;
  var _lens = CameraLensDirection.back;
  var _initToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreCachedThumb();
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _initToken++;
    final controller = _controller;
    _controller = null;
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      final controller = _controller;
      _controller = null;
      controller?.dispose();
      return;
    }

    if (state == AppLifecycleState.resumed && mounted) {
      // inactive'te dispose edildiğinde burası yeniden açmalı (siyah ekran fix).
      _initCamera(preferredLens: _lens);
      _loadLatestGalleryPhoto();
    }
  }

  Future<File> _cacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_cacheFileName');
  }

  Future<void> _restoreCachedThumb() async {
    try {
      final file = await _cacheFile();
      if (!await file.exists()) return;
      final bytes = await file.readAsBytes();
      if (!mounted || bytes.isEmpty) return;
      setState(() {
        _thumbBytes = bytes;
        _lastPhotoPath = file.path;
      });
    } catch (_) {}
  }

  Future<void> _setLastPhoto(String path) async {
    try {
      final source = File(path);
      if (!await source.exists()) return;
      final bytes = await source.readAsBytes();
      final cache = await _cacheFile();
      await cache.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      setState(() {
        _lastPhotoPath = cache.path;
        _thumbBytes = bytes;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _lastPhotoPath = path);
    }
  }

  /// Galerideki en son fotoğrafı thumbnail olarak yükler.
  Future<void> _loadLatestGalleryPhoto() async {
    try {
      final permission = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          iosAccessLevel: IosAccessLevel.readWrite,
        ),
      );
      if (!permission.hasAccess) return;

      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
        filterOption: FilterOptionGroup(
          orders: [
            const OrderOption(type: OrderOptionType.createDate, asc: false),
          ],
        ),
      );
      if (paths.isEmpty) return;

      final assets = await paths.first.getAssetListPaged(page: 0, size: 1);
      if (assets.isEmpty) return;

      final asset = assets.first;
      final bytes = await asset.thumbnailDataWithSize(
        const ThumbnailSize(256, 256),
        quality: 80,
      );
      if (bytes == null || bytes.isEmpty || !mounted) return;

      final cache = await _cacheFile();
      await cache.writeAsBytes(bytes, flush: true);

      final file = await asset.file;
      setState(() {
        _thumbBytes = bytes;
        _lastPhotoPath = file?.path ?? cache.path;
      });
    } catch (_) {}
  }

  Future<void> _initCamera({
    CameraLensDirection preferredLens = CameraLensDirection.back,
  }) async {
    final token = ++_initToken;
    _lens = preferredLens;

    if (mounted) {
      setState(() {
        _initializing = true;
        _error = null;
      });
    }

    final status = await Permission.camera.request();
    if (token != _initToken) return;
    if (!status.isGranted) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'camera_permission_denied'.tr();
      });
      return;
    }

    try {
      _cameras = await availableCameras();
      if (token != _initToken) return;
      if (_cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _initializing = false;
          _error = 'camera_unavailable'.tr();
        });
        return;
      }

      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == preferredLens,
        orElse: () => _cameras.first,
      );
      _lens = camera.lensDirection;

      final previous = _controller;
      _controller = null;
      await previous?.dispose();
      if (token != _initToken) return;

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      if (token != _initToken || !mounted) {
        await controller.dispose();
        return;
      }

      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (_) {}

      if (token != _initToken || !mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _initializing = false;
        _flashOn = false;
        _error = null;
      });

      // Galeri izni kamera init'i bloklamasın.
      unawaited(_loadLatestGalleryPhoto());
    } catch (e) {
      if (token != _initToken || !mounted) return;
      setState(() {
        _controller = null;
        _initializing = false;
        _error = 'camera_unavailable'.tr();
      });
    }
  }

  bool get _isFront => _lens == CameraLensDirection.front;

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isFront) {
      return;
    }
    final next = !_flashOn;
    try {
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (!mounted) return;
      setState(() => _flashOn = next);
    } catch (_) {}
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2 || _capturing || _initializing) return;
    final next = _lens == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    await _initCamera(preferredLens: next);
  }

  Future<void> _openCompose(
    String imagePath, {
    bool fromDraft = false,
    String? draftId,
  }) async {
    if (!mounted) return;
    await _setLastPhoto(imagePath);
    if (!mounted) return;
    await context.push(
      RoutePaths.cameraCompose.path,
      extra: CameraComposeRouteArgs(
        imagePath: imagePath,
        fromDraft: fromDraft,
        draftId: draftId,
      ),
    );
    if (!mounted) return;
    // Compose'tan dönünce preview çoğu zaman dispose olmuş olur.
    if (_controller == null || !_controller!.value.isInitialized) {
      await _initCamera(preferredLens: _lens);
    }
    await _loadLatestGalleryPhoto();
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _capturing ||
        controller.value.isTakingPicture) {
      return;
    }

    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      await _setLastPhoto(file.path);
      try {
        await PhotoManager.editor.saveImageWithPath(file.path);
      } catch (_) {}
      await _openCompose(file.path);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _openGallery() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    await _setLastPhoto(file.path);
    await _openCompose(file.path);
  }

  Future<void> _openDraft() async {
    setState(() => _mode = _CameraMode.draft);
    final pick = await showCameraDraftsSheet(context);
    if (!mounted) return;
    if (pick == null) {
      setState(() => _mode = _CameraMode.story);
      return;
    }
    await _setLastPhoto(pick.imagePath);
    await _openCompose(pick.imagePath, fromDraft: true, draftId: pick.draftId);
  }

  Widget _buildGalleryThumb() {
    if (_thumbBytes != null) {
      return Image.memory(
        _thumbBytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        key: ValueKey('mem_${_thumbBytes!.length}'),
      );
    }
    if (_lastPhotoPath != null) {
      return Image.file(
        File(_lastPhotoPath!),
        fit: BoxFit.cover,
        key: ValueKey(_lastPhotoPath),
        errorBuilder: (_, _, _) =>
            Image.asset(AssetPaths.mapSecond, fit: BoxFit.cover),
      );
    }
    return Image.asset(AssetPaths.mapSecond, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildPreview(),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: const AppIcon(AssetPaths.iconCloose, size: 32),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _toggleFlash,
                          child: AppIcon(
                            AssetPaths.iconFlashSlash,
                            size: 32,
                            color: _flashOn
                                ? AppColors.zoviOrange
                                : AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _capture,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFD9D9D9),
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFD9D9D9),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    color: const Color(0xFF151515),
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 10 + bottomInset),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: _openGallery,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: _buildGalleryThumb(),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ModeLabel(
                              label: 'camera_mode_draft'.tr(),
                              selected: _mode == _CameraMode.draft,
                              onTap: _openDraft,
                            ),
                            const SizedBox(width: 16),
                            _ModeLabel(
                              label: 'camera_mode_story'.tr(),
                              selected: _mode == _CameraMode.story,
                              onTap: () =>
                                  setState(() => _mode = _CameraMode.story),
                            ),
                          ],
                        ),
                        _CircleIconButton(
                          onTap: _flipCamera,
                          child: const AppIcon(
                            AssetPaths.iconRepeatArrow,
                            size: 24,
                            color: AppColors.white,
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
      ),
    );
  }

  Widget _buildPreview() {
    final controller = _controller;
    final ready =
        !_initializing &&
        controller != null &&
        controller.value.isInitialized &&
        controller.value.previewSize != null;

    if (_error != null && !ready) {
      return ColoredBox(
        color: AppColors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => _initCamera(preferredLens: _lens),
                  child: Text(
                    'camera_retry'.tr(),
                    style: const TextStyle(color: AppColors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!ready) {
      return const ColoredBox(
        color: AppColors.black,
        child: AppLoading(),
      );
    }

    final previewSize = controller.value.previewSize!;
    return ColoredBox(
      color: AppColors.black,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewSize.height,
            height: previewSize.width,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 42,
        height: 42,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white.withValues(alpha: 0.15),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _ModeLabel extends StatelessWidget {
  const _ModeLabel({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1,
          letterSpacing: -0.32,
          color: AppColors.white.withValues(alpha: selected ? 1 : 0.45),
        ),
      ),
    );
  }
}
