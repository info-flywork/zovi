import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zovi/core/theme/app_colors.dart';

/// 6 haneli OTP kutuları + altındaki tekrar gönder satırı.
@immutable
final class OtpCodeField extends StatelessWidget {
  const OtpCodeField({
    required this.code,
    required this.onChanged,
    required this.canResend,
    required this.resendSeconds,
    required this.isResending,
    required this.onResend,
    this.autofocus = true,
    super.key,
  });

  final String code;
  final ValueChanged<String> onChanged;
  final bool canResend;
  final int resendSeconds;
  final bool isResending;
  final VoidCallback onResend;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OtpDigitRow(
          code: code,
          onChanged: onChanged,
          autofocus: autofocus,
        ),
        const SizedBox(height: 16),
        _OtpResendRow(
          canResend: canResend,
          resendSeconds: resendSeconds,
          isResending: isResending,
          onResend: onResend,
        ),
      ],
    );
  }
}

@immutable
final class _OtpDigitRow extends StatefulWidget {
  const _OtpDigitRow({
    required this.code,
    required this.onChanged,
    required this.autofocus,
  });

  final String code;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  @override
  State<_OtpDigitRow> createState() => _OtpDigitRowState();
}

final class _OtpDigitRowState extends State<_OtpDigitRow> {
  late final FocusNode _focusNode;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(() => setState(() {}));
    _controller = TextEditingController(text: widget.code);
  }

  @override
  void didUpdateWidget(covariant _OtpDigitRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code && _controller.text != widget.code) {
      _controller
        ..text = widget.code
        ..selection = TextSelection.collapsed(offset: widget.code.length);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  int get _activeIndex {
    if (!_focusNode.hasFocus) {
      return widget.code.length.clamp(0, 5);
    }
    return widget.code.length.clamp(0, 5);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        SizedBox(
          width: 1,
          height: 1,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: widget.onChanged,
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          behavior: HitTestBehavior.translucent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              final digit = index < widget.code.length ? widget.code[index] : '';
              final isFilled = digit.isNotEmpty;
              final isActive = _focusNode.hasFocus && index == _activeIndex;

              return _OtpDigitBox(
                digit: digit,
                isFilled: isFilled,
                isActive: isActive,
              );
            }),
          ),
        ),
      ],
    );
  }
}

@immutable
final class _OtpDigitBox extends StatelessWidget {
  const _OtpDigitBox({
    required this.digit,
    required this.isFilled,
    required this.isActive,
  });

  final String digit;
  final bool isFilled;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isFilled || isActive ? AppColors.warmAmber : AppColors.creamBase;

    return Container(
      width: 44,
      height: 60,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      alignment: Alignment.center,
      child: Text(
        digit,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          height: 40 / 32,
          letterSpacing: -0.64,
          color: AppColors.zoviOrange,
        ),
      ),
    );
  }
}

@immutable
final class _OtpResendRow extends StatelessWidget {
  const _OtpResendRow({
    required this.canResend,
    required this.resendSeconds,
    required this.isResending,
    required this.onResend,
  });

  final bool canResend;
  final int resendSeconds;
  final bool isResending;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 20 / 16,
          letterSpacing: -0.32,
        ),
        children: [
          TextSpan(
            text: 'otp_resend_prompt'.tr(),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: canResend && !isResending ? onResend : null,
              child: Text(
                isResending
                    ? 'sending'.tr()
                    : canResend
                        ? 'resend'.tr()
                        : 'resend_in_seconds'.tr(
                            namedArgs: {'seconds': '$resendSeconds'},
                          ),
                style: TextStyle(
                  color: canResend && !isResending
                      ? AppColors.zoviOrange
                      : AppColors.zoviOrange.withValues(alpha: 0.65),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 20 / 16,
                  letterSpacing: -0.32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
