import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/push/push_notification_service.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/utils/extensions/future_extensions.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/profile/settings/view/widgets/account_privacy_sheet.dart';
import 'package:zovi/presentation/profile/settings/view/widgets/blocked_users_sheet.dart';
import 'package:zovi/presentation/profile/settings/view/widgets/language_sheet.dart';
import 'package:zovi/presentation/profile/settings/view/widgets/logout_sheet.dart';

@immutable
final class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

final class _SettingsViewState extends State<SettingsView>
    with WidgetsBindingObserver {
  bool _notificationsEnabled = false;
  bool _locationEnabled = false;
  bool _isUpdatingNotifications = false;
  bool _isUpdatingLocation = false;
  AccountPrivacy _accountPrivacy = AccountPrivacy.public;
  bool _isUpdatingAccountPrivacy = false;
  AppLanguage? _selectedLanguage;
  List<BlockedUser> _blockedUsers = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final cached = getIt<UserRepository>().cachedCurrentUser;
    _accountPrivacy = _privacyFromRaw(cached?.accountPrivacy);
    _syncNotificationPermission();
    _syncLocationPermission();
    _syncAccountPrivacyFromBackend();
    _syncBlockedUsersFromBackend();
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
    if (_isUpdatingAccountPrivacy) return;
    final selected = await showAccountPrivacySheet(
      context,
      initial: _accountPrivacy,
    );
    if (selected == null || !mounted) return;
    if (selected == _accountPrivacy) return;

    _isUpdatingAccountPrivacy = true;
    try {
      final raw = switch (selected) {
        AccountPrivacy.public => 'public',
        AccountPrivacy.friends => 'friends',
      };
      await getIt<AuthRepository>()
          .updateAccountPrivacy(raw)
          .withLoading(context);
      if (!mounted) return;
      setState(() => _accountPrivacy = selected);
      final repo = getIt<UserRepository>();
      final cached = repo.cachedCurrentUser;
      if (cached != null) {
        repo.updateCurrentUser(cached.copyWith(accountPrivacy: raw));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('error_profile_save_failed'.tr())));
    } finally {
      _isUpdatingAccountPrivacy = false;
    }
  }

  Future<void> _syncAccountPrivacyFromBackend() async {
    try {
      final payload = await getIt<AuthRepository>().fetchMyProfilePayload();
      final profile = payload['profile'];
      final profileMap = profile is Map<String, dynamic>
          ? profile
          : const <String, dynamic>{};
      final raw = (profileMap['accountPrivacy'] as String?)
          ?.trim()
          .toLowerCase();
      if (!mounted) return;
      final privacy = _privacyFromRaw(raw);
      setState(() => _accountPrivacy = privacy);
      final repo = getIt<UserRepository>();
      final cached = repo.cachedCurrentUser;
      if (cached != null) {
        repo.updateCurrentUser(
          cached.copyWith(
            accountPrivacy: raw == 'friends' ? 'friends' : 'public',
          ),
        );
      }
    } catch (_) {
      // Cache-first UX: keep current value on transient failures.
    }
  }

  AccountPrivacy _privacyFromRaw(String? raw) {
    return raw == 'friends' ? AccountPrivacy.friends : AccountPrivacy.public;
  }

  Future<void> _openBlockedUsers() async {
    final previous = List<BlockedUser>.from(_blockedUsers);
    final updated = await showBlockedUsersSheet(context, users: _blockedUsers);
    if (!mounted) return;
    setState(() => _blockedUsers = updated);

    final removedIds = previous
        .where((oldUser) => oldUser.userId.isNotEmpty)
        .where((oldUser) => !updated.any((u) => u.userId == oldUser.userId))
        .map((u) => u.userId)
        .toList();
    if (removedIds.isEmpty) return;

    try {
      await Future.wait(
        removedIds.map((id) => getIt<AuthRepository>().unblockUser(id)),
      );
      await _syncBlockedUsersFromBackend();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('error_profile_save_failed'.tr())));
      await _syncBlockedUsersFromBackend();
    }
  }

  Future<void> _syncBlockedUsersFromBackend() async {
    try {
      final blocked = await getIt<AuthRepository>().fetchBlockedUsers();
      if (!mounted) return;
      setState(() {
        _blockedUsers = blocked
            .map(
              (item) => BlockedUser(
                userId: item.userId,
                username: item.username.isEmpty ? 'user' : item.username,
                avatarPath: item.avatarUrl,
              ),
            )
            .toList();
      });
    } catch (_) {
      // Keep last known value on failures.
    }
  }

  Future<void> _logout() async {
    final confirmed = await showLogoutSheet(context);
    if (!confirmed || !mounted) return;
    try {
      final logout = getIt<AuthRepository>().logout();
      await getIt<PushNotificationService>().logout();
      if (!mounted) return;
      await logout.withLoading(context);
      getIt<UserRepository>().clearSessionCache();
      if (!mounted) return;
      context.go(RoutePaths.onboarding.path);
      await resetUserScopedSingletons();
    } catch (_) {
      getIt<UserRepository>().clearSessionCache();
      if (!mounted) return;
      context.go(RoutePaths.onboarding.path);
      await resetUserScopedSingletons();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _SettingsHeader(),
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
                  _SettingsNavRow(
                    icon: AssetPaths.iconReturningVisitor,
                    label: 'profile_viewers_title'.tr(),
                    onTap: () => context.push(RoutePaths.profileViewers.path),
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

@immutable
final class _SettingsHeader extends StatelessWidget {
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

@immutable
final class _SectionLabel extends StatelessWidget {
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

@immutable
final class _SettingsNavRow extends StatelessWidget {
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

@immutable
final class _SettingsSwitchRow extends StatelessWidget {
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
