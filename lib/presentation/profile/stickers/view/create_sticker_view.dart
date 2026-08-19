import 'dart:io';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/snackbar/app_snackbar.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/utils/extensions/future_extensions.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/profile/stickers/view/widgets/create_sticker_confirm_sheet.dart';

enum _StickerStyle {
  modern('🎨', 'sticker_style_modern'),
  sketch('✏️', 'sticker_style_sketch'),
  colorful('🌈', 'sticker_style_colorful'),
  anime('🔥', 'sticker_style_anime');

  const _StickerStyle(this.emoji, this.labelKey);
  final String emoji;
  final String labelKey;

  String get label => labelKey.tr();
}

@immutable
final class CreateStickerView extends StatefulWidget {
  const CreateStickerView({super.key});

  @override
  State<CreateStickerView> createState() => _CreateStickerViewState();
}

final class _CreateStickerViewState extends State<CreateStickerView> {
  static const _uploadFill = Color(0xFFF4F4F9);
  static const _uploadBorder = Color(0xFFD2D2DA);
  static const _fieldFill = Color(0xFFF4F4F9);
  static const _hintGray = Color(0xFF9999A0);

  final _imagePicker = ImagePicker();
  final AuthRepository _authRepository = getIt<AuthRepository>();
  final UserRepository _userRepository = getIt<UserRepository>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  _StickerStyle _selectedStyle = _StickerStyle.modern;
  String? _imagePath;
  var _isSubmitting = false;

  void _dismissKeyboard() {
    final focus = FocusScope.of(context);
    if (!focus.hasPrimaryFocus && focus.focusedChild != null) {
      focus.unfocus();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _pickImageFlow(source).withLoading(context);
      if (!mounted || image == null) return;
      setState(() => _imagePath = image.path);
    } on _PermissionDeniedException {
      if (!mounted) return;
      AppSnackbar.instance.show(
        context,
        'chat_permission_denied'.tr(),
        isError: true,
      );
    }
  }

  Future<XFile?> _pickImageFlow(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) throw const _PermissionDeniedException();
    }
    return _imagePicker.pickImage(source: source, imageQuality: 85);
  }

  Future<void> _onContinue() async {
    final imagePath = _imagePath;
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (imagePath == null || imagePath.isEmpty) {
      AppSnackbar.instance.show(
        context,
        'sticker_error_select_photo'.tr(),
        isError: true,
      );
      return;
    }
    if (name.isEmpty) {
      AppSnackbar.instance.show(
        context,
        'sticker_error_name_required'.tr(),
        isError: true,
      );
      return;
    }
    if (description.isEmpty) {
      AppSnackbar.instance.show(
        context,
        'sticker_error_description_required'.tr(),
        isError: true,
      );
      return;
    }

    final coinBalance = _userRepository.currentUserListenable.value?.coins ?? 0;
    final action = await showCreateStickerConfirmSheet(
      context,
      coinBalance: coinBalance,
    );
    if (!mounted || action == null) return;
    if (action == CreateStickerConfirmAction.buyCoins) return;

    await _submitCreateSticker();
  }

  Future<void> _submitCreateSticker() async {
    if (_isSubmitting) return;

    final path = _imagePath;
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    if (path == null || path.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await _authRepository
          .generateSticker(
            imagePath: path,
            style: _selectedStyle.name,
            name: name,
            description: description,
          )
          .withLoading(context);
      final coinsBalance = result.coinsBalance;
      if (coinsBalance != null) {
        final current = _userRepository.currentUserListenable.value;
        if (current != null && current.coins != coinsBalance) {
          _userRepository.currentUserListenable.value = current.copyWith(
            coins: coinsBalance,
          );
        }
      }
      if (!mounted) return;
      final completed = await context.push<bool>(
        RoutePaths.createStickerSuccess.path,
      );
      if (!mounted) return;
      if (completed == true) {
        context.pop(true);
      }
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.instance.show(
        context,
        'sticker_error_create_failed'.tr(),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: GestureDetector(
        onTap: _dismissKeyboard,
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: Column(
            children: [
              const _CreateStickerHeader(),
              Expanded(
                child: ListView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _UploadCard(
                      imagePath: _imagePath,
                      onUpload: () => _pickImage(ImageSource.gallery),
                      onCamera: () => _pickImage(ImageSource.camera),
                      uploadFill: _uploadFill,
                      uploadBorder: _uploadBorder,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'sticker_select_style'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1,
                        letterSpacing: -0.32,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (final style in _StickerStyle.values) ...[
                          if (style != _StickerStyle.values.first)
                            const SizedBox(width: 8),
                          Expanded(
                            child: _StyleChip(
                              style: style,
                              isSelected: style == _selectedStyle,
                              onTap: () =>
                                  setState(() => _selectedStyle = style),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'sticker_name_label'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1,
                        letterSpacing: -0.32,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _RoundedField(
                      controller: _nameController,
                      hintText: 'sticker_name_hint'.tr(),
                      fillColor: _fieldFill,
                      hintColor: _hintGray,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'sticker_description_label'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1,
                        letterSpacing: -0.32,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _RoundedField(
                      controller: _descriptionController,
                      hintText: 'sticker_description_hint'.tr(),
                      fillColor: _fieldFill,
                      hintColor: _hintGray,
                      maxLines: 6,
                      minHeight: 140,
                    ),
                  ],
                ),
              ),
              _ContinueButton(onTap: _onContinue),
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
final class _PermissionDeniedException implements Exception {
  const _PermissionDeniedException();
}

@immutable
final class _CreateStickerHeader extends StatelessWidget {
  const _CreateStickerHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              behavior: HitTestBehavior.opaque,
              child: const AppIcon(AssetPaths.iconBack, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'sticker_create'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
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

@immutable
final class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.imagePath,
    required this.onUpload,
    required this.onCamera,
    required this.uploadFill,
    required this.uploadBorder,
  });

  final String? imagePath;
  final VoidCallback onUpload;
  final VoidCallback onCamera;
  final Color uploadFill;
  final Color uploadBorder;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(
        color: uploadBorder,
        radius: 12,
        strokeWidth: 1,
        dashWidth: 3,
        dashGap: 3,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
        decoration: BoxDecoration(
          color: uploadFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            if (imagePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(imagePath!),
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFFFFF), Color(0xFFA9A9A9)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.chatPurple.withValues(alpha: 0.30),
                      blurRadius: 10,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(1),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.alphaBlend(
                      AppColors.chatPurple.withValues(alpha: 0.20),
                      const Color(0xFFF4F4F9),
                    ),
                  ),
                  child: const Center(
                    child: AppIcon(AssetPaths.iconStampGallery, size: 48),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'sticker_create'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1,
                  letterSpacing: -0.32,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'sticker_create_subtitle'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  letterSpacing: -0.28,
                  color: AppColors.black.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 24),
            ],
            _PillButton(
              label: 'sticker_upload_file'.tr(),
              iconAsset: AssetPaths.iconStampExportArrow,
              background: AppColors.deepRoast,
              foreground: AppColors.white,
              onTap: onUpload,
            ),
            const SizedBox(height: 10),
            _PillButton(
              label: 'sticker_take_photo'.tr(),
              iconAsset: AssetPaths.iconStampCamera,
              background: AppColors.white,
              foreground: AppColors.deepRoast,
              borderColor: const Color(0xFFE2E2E2),
              onTap: onCamera,
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
final class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.iconAsset,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.borderColor,
  });

  final String label;
  final String iconAsset;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(9999),
          border: borderColor == null ? null : Border.all(color: borderColor!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(iconAsset, size: 20, color: foreground),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1,
                letterSpacing: -0.32,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
final class _StyleChip extends StatelessWidget {
  const _StyleChip({
    required this.style,
    required this.isSelected,
    required this.onTap,
  });

  final _StickerStyle style;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 95,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.zoviOrange.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(style.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 10),
            Text(
              style.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1,
                letterSpacing: -0.28,
                color: isSelected ? AppColors.zoviOrange : AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
final class _RoundedField extends StatelessWidget {
  const _RoundedField({
    required this.controller,
    required this.hintText,
    required this.fillColor,
    required this.hintColor,
    required this.maxLines,
    this.minHeight,
  });

  final TextEditingController controller;
  final String hintText;
  final Color fillColor;
  final Color hintColor;
  final int maxLines;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: minHeight == null
          ? null
          : BoxConstraints(minHeight: minHeight!),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.2,
          letterSpacing: -0.32,
          color: AppColors.black,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.2,
            letterSpacing: -0.32,
            color: hintColor,
          ),
        ),
      ),
    );
  }
}

@immutable
final class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.deepRoast,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            'continue'.tr(),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1,
              letterSpacing: -0.34,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}

@immutable
final class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashGap,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final dashed = _dashPath(path, dashWidth: dashWidth, dashGap: dashGap);
    canvas.drawPath(dashed, paint);
  }

  Path _dashPath(
    Path source, {
    required double dashWidth,
    required double dashGap,
  }) {
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final length = math.min(
          draw ? dashWidth : dashGap,
          metric.length - distance,
        );
        if (draw) {
          dashed.addPath(
            metric.extractPath(distance, distance + length),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
    return dashed;
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashGap != dashGap;
  }
}
