import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/core/snackbar/app_snackbar.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/profile/add_plan/model/add_plan_place.dart';
import 'package:zovi/presentation/profile/add_plan/model/add_plan_success_route_args.dart';

class AddPlanDetailsView extends StatefulWidget {
  const AddPlanDetailsView({required this.place, super.key});

  final AddPlanPlace place;

  @override
  State<AddPlanDetailsView> createState() => _AddPlanDetailsViewState();
}

class _AddPlanDetailsViewState extends State<AddPlanDetailsView> {
  static const _timeSlots = [
    '00:00',
    '02:00',
    '04:00',
    '06:00',
    '08:00',
    '10:00',
    '12:00',
    '14:00',
    '16:00',
    '18:00',
    '20:00',
    '22:00',
  ];

  static const _initialVisibleStartIndex = 6; // 12:00
  static const _timeChipWidth = 75.0;
  static const _timeChipGap = 10.0;

  late final TextEditingController _noteController;
  late final ScrollController _timeScrollController;
  String _selectedTime = '14:00';
  bool _showToFriends = true;
  bool _showToNearby = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _timeScrollController = ScrollController(
      initialScrollOffset:
          _initialVisibleStartIndex * (_timeChipWidth + _timeChipGap),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _timeScrollController.dispose();
    super.dispose();
  }

  DateTime _scheduledAtForSelectedTime() {
    final now = DateTime.now();
    final parts = _selectedTime.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  Future<void> _onSavePlan() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    FocusScope.of(context).unfocus();

    try {
      await getIt<UserRepository>().createPlan(
        placeName: widget.place.placeName,
        subtitle: widget.place.subtitle,
        category: widget.place.categoryKey,
        scheduledAt: _scheduledAtForSelectedTime(),
        showToFriends: _showToFriends,
        showToNearby: _showToNearby,
        note: _noteController.text.trim(),
      );
      if (!mounted) return;
      await context.push(
        RoutePaths.addPlanSuccess.path,
        extra: AddPlanSuccessRouteArgs(
          place: widget.place,
          showToFriends: _showToFriends,
          showToNearby: _showToNearby,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.instance.show(
        context,
        'plan_save_failed'.tr(),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Column(
            children: [
              const _DetailsHeader(),
              Expanded(
                child: ListView(
                  physics: const ClampingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(top: 12, bottom: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SelectedPlaceCard(
                        place: widget.place,
                        onChangeTap: () => context.pop(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'select_time'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1,
                          letterSpacing: -0.32,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: screenWidth,
                      height: 40,
                      child: ListView.separated(
                        controller: _timeScrollController,
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _timeSlots.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final time = _timeSlots[index];
                          final isSelected = time == _selectedTime;
                          return SizedBox(
                            width: _timeChipWidth,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedTime = time),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.zoviOrange
                                      : AppColors.white,
                                  borderRadius: BorderRadius.circular(9999),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.zoviOrange
                                        : const Color(0xFFE2E2E2),
                                  ),
                                ),
                                child: Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    height: 1,
                                    letterSpacing: -0.32,
                                    color: isSelected
                                        ? AppColors.white
                                        : AppColors.deepRoast,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 26),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'add_note'.tr(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    height: 1,
                                    letterSpacing: -0.32,
                                    color: AppColors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ${'optional'.tr()}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    height: 1,
                                    letterSpacing: -0.28,
                                    color: AppColors.deepRoast,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 88,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F4F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _noteController,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              onTapOutside: (_) =>
                                  FocusManager.instance.primaryFocus?.unfocus(),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                hintText: 'note_hint'.tr(),
                                hintStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                  letterSpacing: -0.32,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                                letterSpacing: -0.32,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          _VisibilitySwitchRow(
                            title: 'show_to_friends_title'.tr(),
                            subtitle: 'show_to_friends_subtitle'.tr(),
                            value: _showToFriends,
                            onChanged: (value) =>
                                setState(() => _showToFriends = value),
                          ),
                          const SizedBox(height: 16),
                          _VisibilitySwitchRow(
                            title: 'show_to_nearby_title'.tr(),
                            subtitle: 'show_to_nearby_subtitle'.tr(),
                            value: _showToNearby,
                            onChanged: (value) =>
                                setState(() => _showToNearby = value),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _SaveButton(isLoading: _isSaving, onTap: _onSavePlan),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader();

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
              'details_title'.tr(),
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

class _SelectedPlaceCard extends StatelessWidget {
  const _SelectedPlaceCard({required this.place, required this.onChangeTap});

  final AddPlanPlace place;
  final VoidCallback onChangeTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.zoviOrange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.zoviOrange),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.zoviOrange.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const AppIcon(AssetPaths.iconLocationFilled, size: 40),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.placeName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    letterSpacing: -0.32,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  place.subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1,
                    letterSpacing: -0.28,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onChangeTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'change'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1,
                  letterSpacing: -0.32,
                  color: AppColors.zoviOrange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibilitySwitchRow extends StatelessWidget {
  const _VisibilitySwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1,
                  letterSpacing: -0.32,
                  color: AppColors.deepRoast,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1,
                  letterSpacing: -0.28,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: const Color(0xFF33C658),
          activeThumbColor: AppColors.white,
          inactiveTrackColor: const Color(0xFFD0D0D0),
          inactiveThumbColor: AppColors.white,
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.onTap, required this.isLoading});

  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: GestureDetector(
          onTap: isLoading ? null : onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.deepRoast,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.white,
                        ),
                      )
                    : Text(
                        'save_plan'.tr(),
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
          ),
        ),
      ),
    );
  }
}
