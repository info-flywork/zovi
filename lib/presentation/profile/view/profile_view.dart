import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/core/widgets/app_loading.dart';
import 'package:zovi/core/widgets/bottom_navigation_bar/main_wrapper.dart';
import 'package:zovi/core/widgets/profile_avatar.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/profile/bloc/profile_bloc.dart';
import 'package:zovi/presentation/profile/connections/model/profile_connections_route_args.dart';
import 'package:zovi/presentation/profile/edit/model/edit_profile_route_args.dart';
import 'package:zovi/presentation/profile/view/widgets/profile_share_sheet.dart';

part 'mixin/profile_view_mixin.dart';
part 'widgets/profile_loaded_body.dart';
part 'widgets/profile_header.dart';
part 'widgets/profile_stats.dart';
part 'widgets/profile_map.dart';
part 'widgets/profile_plans.dart';
part 'widgets/profile_tabs.dart';
part 'widgets/profile_pulses.dart';
part 'widgets/profile_stamps.dart';
part 'widgets/profile_checkins.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with TickerProviderStateMixin, ProfileViewMixin {
  @override
  void initState() {
    super.initState();
    initProfileTabs();
    context.read<ProfileBloc>().add(const ProfileStarted());
  }

  @override
  void dispose() {
    disposeProfileTabs();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            return switch (state) {
              ProfileLoaded(
                :final user,
                :final checkIns,
                :final pulses,
                :final stamps,
                :final plans,
              ) =>
                ProfileLoadedBody(
                  user: user,
                  checkIns: checkIns,
                  pulses: pulses,
                  stamps: stamps,
                  plans: plans,
                  tabController: tabController,
                  onTabSelected: onTabSelected,
                ),
              ProfileError(:final message) => Center(child: Text(message)),
              _ => const AppLoading(),
            };
          },
        ),
      ),
    );
  }
}
