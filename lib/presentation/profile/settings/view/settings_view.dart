import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/presentation/profile/settings/view/widgets/account_privacy_sheet.dart';
import 'package:zovi/presentation/profile/settings/view/widgets/blocked_users_sheet.dart';
import 'package:zovi/presentation/profile/settings/view/widgets/language_sheet.dart';
import 'package:zovi/presentation/profile/settings/view/widgets/logout_sheet.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with WidgetsBindingObserver {
  bool _notificationsEnabled = false;
  bool _locationEnabled = false;
  bool _isUpdatingNotifications = false;
  bool _isUpdatingLocation = false;
  AccountPrivacy _accountPrivacy = AccountPrivacy.public;
  AppLanguage? _selectedLanguage;
  List<BlockedUser> _blockedUsers = const [
    BlockedUser(
      username: 'juliaivanova',
      avatarPath: AssetPaths.avatarJulia,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncNotificationPermission();
    _syncLocationPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncNotificationPermission();
      _syncLocationPermission();
    }
  }

  Future<void> _syncNotificationPermission() async {
    final status = await Permission.notification.status;
    if (!mounted) return;
    setState(() => _notificationsEnabled = status.isGranted);
  }

  Future<void> _syncLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    if (!mounted) return;
    setState(() => _locationEnabled = status.isGranted);
  }

  Future<void> _onNotificationsChanged(bool enabled) async {
    if (_isUpdatingNotifications) return;
    _isUpdatingNotifications = true;

    try {
      if (enabled) {
        final status = await Permission.notification.status;
        if (status.isPermanentlyDenied) {
          await openAppSettings();
        } else {
          final result = await Permission.notification.request();
          if (!mounted) return;
          setState(() => _notificationsEnabled = result.isGranted);
          return;
        }
      } else {
        await openAppSettings();
      }
      await _syncNotificationPermission();
    } finally {
      _isUpdatingNotifications = false;
    }
  }

  Future<void> _onLocationChanged(bool enabled) async {
    if (_isUpdatingLocation) return;
    _isUpdatingLocation = true;

    try {
      if (enabled) {
        final status = await Permission.locationWhenInUse.status;
        if (status.isPermanentlyDenied) {
          await openAppSettings();
        } else {
          final result = await Permission.locationWhenInUse.request();
          if (!mounted) return;
          setState(() => _locationEnabled = result.isGranted);
          return;
        }
      } else {
        await openAppSettings();
      }
      await _syncLocationPermission();
    } finally {
      _isUpdatingLocation = false;
    }
  }

  AppLanguage get _currentLanguage =>
      _selectedLanguage ?? AppLanguage.fromLocale(context.locale);

  String get _languageLabel => _currentLanguage.label;

  Future<void> _pickLanguage() async {
    final selected = await showLanguageSheet(
      context,
      initial: _currentLanguage,
    );
    if (selected == null || !mounted) return;
    setState(() => _selectedLanguage = selected);
    await context.setLocale(selected.appLocale);
  }

  String get _privacyLabel {
    return switch (_accountPrivacy) {
      AccountPrivacy.public => 'settings_privacy_public'.tr(),
      AccountPrivacy.friends => 'settings_privacy_friends'.tr(),
    };
  }

  Future<void> _pickAccountPrivacy() async {
    final selected = await showAccountPrivacySheet(
      context,
      initial: _accountPrivacy,
    );
    if (selected == null || !mounted) return;
    setState(() => _accountPrivacy = selected);
  }

  Future<void> _openBlockedUsers() async {
    final updated = await showBlockedUsersSheet(
      context,
      users: _blockedUsers,
    );
    if (!mounted) return;
    setState(() => _blockedUsers = updated);
  }

  Future<void> _logout() async {
    final confirmed = await showLogoutSheet(context);
    if (!confirmed || !mounted) return;
    await getIt<AuthRepository>().logout();
    if (!mounted) return;
    context.go(RoutePaths.onboarding.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const _SettingsHeader(),
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _SectionLabel(label: 'settings_section_account'.tr()),
                  const SizedBox(height: 8),
                  _SettingsNavRow(
                    icon: AssetPaths.iconUserSquare,
                    label: 'settings_personal_info'.tr(),
                    onTap: () => context.push(RoutePaths.personalInfo.path),
                  ),
                  //                  _SettingsNavRow(
                  //                  icon: AssetPaths.iconKey,
                  //                label: 'settings_change_password'.tr(),
                  //              onTap: () => context.push(RoutePaths.changePassword.path),
                  //          ),
                  const SizedBox(height: 20),
                  _SectionLabel(label: 'settings_section_app'.tr()),
                  const SizedBox(height: 8),
                  _SettingsSwitchRow(
                    icon: AssetPaths.iconNotificationBing,
                    label: 'settings_notifications'.tr(),
                    value: _notificationsEnabled,
                    onChanged: _onNotificationsChanged,
                  ),
                  _SettingsNavRow(
                    icon: AssetPaths.iconSecurity,
                    label: 'settings_account_privacy'.tr(),
                    trailingText: _privacyLabel,
                    onTap: _pickAccountPrivacy,
                  ),
                  _SettingsNavRow(
                    icon: AssetPaths.iconForbidden,
                    label: 'settings_blocked'.tr(),
                    trailingText: '${_blockedUsers.length}',
                    onTap: _openBlockedUsers,
                  ),
                  _SettingsNavRow(
                    icon: AssetPaths.iconLanguageSquare,
                    label: 'settings_language'.tr(),
                    trailingText: _languageLabel,
                    onTap: _pickLanguage,
                  ),
                  _SettingsSwitchRow(
                    icon: AssetPaths.iconLocation7,
                    label: 'settings_location'.tr(),
                    subtitle: 'settings_location_subtitle'.tr(),
                    value: _locationEnabled,
                    onChanged: _onLocationChanged,
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel(label: 'settings_section_login'.tr()),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _logout,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        'settings_logout'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1,
                          letterSpacing: -0.32,
                          color: AppColors.logoutRed,
                        ),
                      ),
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
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

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
            'settings_title'.tr(),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1,
        letterSpacing: -0.28,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _SettingsNavRow extends StatelessWidget {
  const _SettingsNavRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingText,
  });

  final String icon;
  final String label;
  final String? trailingText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            AppIcon(icon, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1,
                  letterSpacing: -0.32,
                  color: AppColors.deepRoast,
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1,
                  letterSpacing: -0.28,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
            ],
            const AppIcon(AssetPaths.iconRight, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          AppIcon(icon, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1,
                    letterSpacing: -0.32,
                    color: AppColors.deepRoast,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1,
                      letterSpacing: -0.28,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 28,
            child: FittedBox(
              fit: BoxFit.contain,
              child: CupertinoSwitch(
                value: value,
                activeTrackColor: AppColors.switchActive,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
