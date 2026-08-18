import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_button.dart';
import 'package:zovi/core/widgets/app_icon.dart';
import 'package:zovi/presentation/auth/intro/bloc/intro_bloc.dart';
import 'package:zovi/presentation/auth/intro/bloc/intro_event.dart';
import 'package:zovi/presentation/auth/intro/bloc/intro_state.dart';

part 'mixin/intro_view_mixin.dart';
part 'widgets/intro_loaded_body.dart';
part 'widgets/intro_around_page.dart';
part 'widgets/intro_pulse_page.dart';
part 'widgets/intro_stamps_page.dart';

@immutable
final class IntroView extends StatefulWidget {
  const IntroView({super.key});

  @override
  State<IntroView> createState() => _IntroViewState();
}

final class _IntroViewState extends State<IntroView> with IntroViewMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: BlocConsumer<IntroBloc, IntroState>(
          listener: (context, state) {
            if (state is IntroCompleted) {
              context.go(state.navigateTo);
            } else if (state is IntroInProgress) {
              syncPage(state.pageIndex);
            }
          },
          builder: (context, state) {
            return IntroLoadedBody(
              pageController: pageController,
              pageIndex: state.pageIndex,
              onPageChanged: onPageChanged,
              onContinue: onContinue,
              onGetStarted: onGetStarted,
            );
          },
        ),
      ),
    );
  }
}
