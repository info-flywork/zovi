import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/otp_code_field.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  static const _handle = 'jhondoe4512';
  static const _email = 'jhondoe4512@gmail.com';
  static const _resendDuration = 30;

  String _code = '';
  int _resendSeconds = _resendDuration;
  bool _isResending = false;
  Timer? _timer;

  bool get _canResend => _resendSeconds <= 0 && !_isResending;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendSeconds = _resendDuration);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _resendSeconds = 0);
        return;
      }
      if (mounted) setState(() => _resendSeconds -= 1);
    });
  }

  void _onCodeChanged(String value) {
    setState(() => _code = value);
  }

  Future<void> _onResend() async {
    if (!_canResend) return;
    setState(() => _isResending = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _isResending = false;
      _code = '';
    });
    _startResendTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ChangePasswordHeader(),
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Text(
                    'change_password_account'.tr(
                      namedArgs: {'handle': _handle},
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 20 / 16,
                      letterSpacing: -0.32,
                      color: AppColors.deepRoast,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'otp_title'.tr(),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w500,
                      height: 48 / 36,
                      letterSpacing: -0.72,
                      color: AppColors.deepRoast,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'otp_email_subtitle'.tr(namedArgs: {'email': _email}),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 20 / 16,
                      letterSpacing: -0.32,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  OtpCodeField(
                    code: _code,
                    onChanged: _onCodeChanged,
                    canResend: _canResend,
                    resendSeconds: _resendSeconds,
                    isResending: _isResending,
                    onResend: _onResend,
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

class _ChangePasswordHeader extends StatelessWidget {
  const _ChangePasswordHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
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
            'change_password_title'.tr(),
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
    );
  }
}
