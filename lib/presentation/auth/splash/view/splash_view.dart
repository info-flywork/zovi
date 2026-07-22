import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/theme/app_theme.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/presentation/auth/splash/bloc/splash_bloc.dart';
import 'package:zovi/presentation/auth/splash/bloc/splash_event.dart';
import 'package:zovi/presentation/auth/splash/bloc/splash_state.dart';

part 'mixin/splash_view_mixin.dart';
part 'widgets/splash_logo.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SplashViewMixin {
  @override
  void initState() {
    super.initState();
    context.read<SplashBloc>().add(const SplashStarted());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashBloc, SplashState>(
      listener: (context, state) {
        if (state is SplashNavigateTo) {
          context.go(state.destination);
        }
      },
      child: const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(child: SplashLogo()),
      ),
    );
  }
}
