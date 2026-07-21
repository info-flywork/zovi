import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _remaining =>
      widget.field.maxLength - _controller.text.characters.length;

  void _onDone() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    context.pop(value);
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
            if (field.isMultiline)
              Expanded(child: _buildInputArea(field))
            else
              _buildInputArea(field),
            if (!field.isMultiline) const Spacer(),
            SafeArea(
              top: false,
              child: _EditFieldBottomSection(
                remaining: _remaining,
                footerText: field.footerText!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(EditProfileFieldType field) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderDivider),
        ),
      ),
      child: _buildTextField(field),
    );
  }

  Widget _buildTextField(EditProfileFieldType field) {
    return TextField(
      controller: _controller,
      autofocus: true,
      maxLength: field.maxLength,
      maxLines: field.isMultiline ? null : 1,
      minLines: field.isMultiline ? 1 : 1,
      expands: field.isMultiline,
      keyboardType:
          field.isMultiline ? TextInputType.multiline : TextInputType.text,
      textInputAction:
          field.isMultiline ? TextInputAction.newline : TextInputAction.done,
      onSubmitted: field.isMultiline ? null : (_) => _onDone(),
      inputFormatters: [
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

class _EditFieldBottomSection extends StatelessWidget {
  const _EditFieldBottomSection({
    required this.remaining,
    required this.footerText,
  });

  final int remaining;
  final String footerText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$remaining',
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
        const Divider(height: 1, thickness: 1, color: AppColors.borderLight),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Text(
            footerText,
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
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  'Done',
                  style: TextStyle(
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
