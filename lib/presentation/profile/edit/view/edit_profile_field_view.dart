import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/extensions/future_extensions.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/app_loading.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/domain/auth/models/username_availability.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/profile/edit/model/edit_profile_field_type.dart';

class EditProfileFieldView extends StatefulWidget {
  const EditProfileFieldView({
    required this.field,
    required this.initialValue,
    super.key,
  });

  final EditProfileFieldType field;
  final String initialValue;

  @override
  State<EditProfileFieldView> createState() => _EditProfileFieldViewState();
}

class _EditProfileFieldViewState extends State<EditProfileFieldView> {
  late final TextEditingController _controller;
  bool _saving = false;
  Timer? _usernameDebounce;
  _UsernameCheckStatus _usernameStatus = _UsernameCheckStatus.idle;
  List<String> _usernameSuggestions = const [];
  String _lastCheckedUsername = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  int get _remaining =>
      widget.field.maxLength - _controller.text.characters.length;

  Future<void> _onDone() async {
    if (_saving) return;
    final value = _controller.text.trim();
    if (value.isEmpty && widget.field != EditProfileFieldType.bio) return;

    // Değişmediyse API yok.
    if (value == widget.initialValue.trim()) {
      context.pop(value);
      return;
    }

    if (widget.field == EditProfileFieldType.username &&
        (_usernameStatus == _UsernameCheckStatus.taken ||
            _usernameStatus == _UsernameCheckStatus.invalid ||
            _usernameStatus == _UsernameCheckStatus.checking)) {
      return;
    }

    _saving = true;
    try {
      final updated = await switch (widget.field) {
        EditProfileFieldType.name => getIt<UserRepository>().patchProfileFields(
            fullName: value,
          ),
        EditProfileFieldType.username =>
          getIt<UserRepository>().patchProfileFields(
            username: value.replaceFirst('@', '').trim(),
          ),
        EditProfileFieldType.bio => getIt<UserRepository>().patchProfileFields(
            bio: value,
          ),
      }.withLoading(context);

      if (!mounted) return;
      final result = switch (widget.field) {
        EditProfileFieldType.name => updated.name,
        EditProfileFieldType.username => updated.usernameHandle,
        EditProfileFieldType.bio => updated.bio,
      };
      context.pop(result);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error_profile_save_failed'.tr())),
      );
    } finally {
      _saving = false;
    }
  }

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();
    final candidate = value.trim().toLowerCase();
    final initial = widget.initialValue.trim().toLowerCase();
    final normalizedInitial = initial.replaceFirst('@', '');

    if (candidate.isEmpty || candidate == normalizedInitial) {
      setState(() {
        _usernameStatus = _UsernameCheckStatus.idle;
        _usernameSuggestions = const [];
      });
      return;
    }

    if (candidate.length < 3) {
      setState(() {
        _usernameStatus = _UsernameCheckStatus.invalid;
        _usernameSuggestions = const [];
      });
      return;
    }

    if (candidate == _lastCheckedUsername) return;

    setState(() {
      _usernameStatus = _UsernameCheckStatus.checking;
      _usernameSuggestions = const [];
    });

    _usernameDebounce = Timer(const Duration(milliseconds: 250), () async {
      if (!mounted) return;
      try {
        final result = await getIt<AuthRepository>()
            .checkUsernameAvailability(candidate);
        if (!mounted) return;
        setState(() {
          _lastCheckedUsername = candidate;
          _usernameStatus = _mapStatus(result);
          _usernameSuggestions = result.available ? const [] : result.suggestions;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _usernameStatus = _UsernameCheckStatus.invalid;
          _usernameSuggestions = const [];
        });
      }
    });
  }

  _UsernameCheckStatus _mapStatus(UsernameAvailability result) {
    if (!result.valid) return _UsernameCheckStatus.invalid;
    if (result.available) return _UsernameCheckStatus.available;
    return _UsernameCheckStatus.taken;
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;

    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _EditFieldHeader(
              title: field.title,
              onBack: () => context.pop(),
              onDone: _onDone,
            ),
            // Input
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: _buildTextField(field),
            ),
            // Çizgi — inputun hemen altında
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.borderDivider,
            ),
            if (field == EditProfileFieldType.username &&
                _usernameStatus != _UsernameCheckStatus.idle)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _UsernameStatusRow(status: _usernameStatus),
              ),
            if (field == EditProfileFieldType.username &&
                _usernameStatus == _UsernameCheckStatus.taken &&
                _usernameSuggestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final suggestion in _usernameSuggestions)
                      GestureDetector(
                        onTap: () {
                          _controller.text = suggestion;
                          _controller.selection = TextSelection.collapsed(
                            offset: suggestion.length,
                          );
                          _onUsernameChanged(suggestion);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceGray,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.borderGray),
                          ),
                          child: Text(
                            suggestion,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.deepRoast,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const Spacer(),
            // 150 + altındaki çizgi — ekranın altında
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$_remaining',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 18 / 16,
                    letterSpacing: -0.32,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.borderDivider,
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Text(
                  field.footerText!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 18 / 16,
                    letterSpacing: -0.32,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(EditProfileFieldType field) {
    final isBio = field.isMultiline;
    return TextField(
      controller: _controller,
      autofocus: true,
      maxLength: field.maxLength,
      maxLines: isBio ? 6 : 1,
      minLines: isBio ? 3 : 1,
      expands: false,
      textAlignVertical: TextAlignVertical.top,
      keyboardType: isBio ? TextInputType.multiline : TextInputType.text,
      textInputAction:
          isBio ? TextInputAction.newline : TextInputAction.done,
      onSubmitted: isBio ? null : (_) => _onDone(),
      onChanged: field == EditProfileFieldType.username ? _onUsernameChanged : null,
      inputFormatters: [
        if (field == EditProfileFieldType.username)
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
        LengthLimitingTextInputFormatter(field.maxLength),
      ],
      decoration: const InputDecoration(
        border: InputBorder.none,
        counterText: '',
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
    );
  }
}

enum _UsernameCheckStatus { idle, checking, available, taken, invalid }

class _UsernameStatusRow extends StatelessWidget {
  const _UsernameStatusRow({required this.status});

  final _UsernameCheckStatus status;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (status) {
      _UsernameCheckStatus.checking => (
        'username_checking'.tr(),
        AppColors.textSecondary,
      ),
      _UsernameCheckStatus.available => (
        'username_available'.tr(),
        AppColors.mintGreen,
      ),
      _UsernameCheckStatus.taken => (
        'username_taken'.tr(),
        AppColors.logoutRed,
      ),
      _UsernameCheckStatus.invalid => (
        'username_invalid'.tr(),
        AppColors.logoutRed,
      ),
      _UsernameCheckStatus.idle => ('', AppColors.textSecondary),
    };

    if (text.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        if (status == _UsernameCheckStatus.checking)
          const AppLoading(size: 14, centered: false)
        else
          Icon(
            status == _UsernameCheckStatus.available
                ? Icons.check_circle_outline
                : Icons.error_outline,
            size: 16,
            color: color,
          ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _EditFieldHeader extends StatelessWidget {
  const _EditFieldHeader({
    required this.title,
    required this.onBack,
    required this.onDone,
  });

  final String title;
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
              title,
              style: const TextStyle(
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
