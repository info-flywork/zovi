import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zovi/core/di/injection.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/core/utils/enum/route_paths.dart';
import 'package:zovi/core/widgets/bottom_navigation_bar/main_wrapper.dart';
import 'package:zovi/presentation/auth/intro/bloc/intro_bloc.dart';
import 'package:zovi/presentation/auth/intro/view/intro_view.dart';
import 'package:zovi/presentation/auth/onboarding/bloc/onboarding_bloc.dart';
import 'package:zovi/presentation/auth/onboarding/view/onboarding_view.dart';
import 'package:zovi/presentation/auth/otp/bloc/otp_bloc.dart';
import 'package:zovi/presentation/auth/otp/model/otp_route_args.dart';
import 'package:zovi/presentation/auth/otp/view/otp_view.dart';
import 'package:zovi/presentation/auth/birthday/bloc/birthday_bloc.dart';
import 'package:zovi/presentation/auth/birthday/model/birthday_route_args.dart';
import 'package:zovi/presentation/auth/birthday/view/birthday_view.dart';
import 'package:zovi/presentation/auth/create_profile/bloc/create_profile_bloc.dart';
import 'package:zovi/presentation/auth/create_profile/model/create_profile_route_args.dart';
import 'package:zovi/presentation/auth/create_profile/view/create_profile_view.dart';
import 'package:zovi/presentation/auth/location_permission/bloc/location_permission_bloc.dart';
import 'package:zovi/presentation/auth/location_permission/view/location_permission_view.dart';
import 'package:zovi/presentation/auth/notification_permission/bloc/notification_permission_bloc.dart';
import 'package:zovi/presentation/auth/notification_permission/model/notification_permission_route_args.dart';
import 'package:zovi/presentation/auth/notification_permission/view/notification_permission_view.dart';
import 'package:zovi/presentation/auth/phone_verified/view/phone_verified_view.dart';
import 'package:zovi/presentation/auth/splash/bloc/splash_bloc.dart';
import 'package:zovi/presentation/auth/splash/view/splash_view.dart';
import 'package:zovi/presentation/chat/bloc/chat_bloc.dart';
import 'package:zovi/presentation/chat/view/chat_view.dart';
import 'package:zovi/presentation/discover/bloc/discover_bloc.dart';
import 'package:zovi/presentation/discover/view/discover_view.dart';
import 'package:zovi/presentation/home/bloc/home_bloc.dart';
import 'package:zovi/presentation/home/view/home_view.dart';
import 'package:zovi/presentation/profile/bloc/profile_bloc.dart';
import 'package:zovi/presentation/profile/edit/model/edit_profile_field_route_args.dart';
import 'package:zovi/presentation/profile/edit/model/edit_profile_links_route_args.dart';
import 'package:zovi/presentation/profile/edit/model/edit_profile_route_args.dart';
import 'package:zovi/presentation/profile/edit/view/add_profile_link_view.dart';
import 'package:zovi/presentation/profile/edit/view/edit_profile_field_view.dart';
import 'package:zovi/presentation/profile/edit/view/edit_profile_links_view.dart';
import 'package:zovi/presentation/profile/edit/view/edit_profile_view.dart';
import 'package:zovi/presentation/profile/add_plan/model/add_plan_details_route_args.dart';
import 'package:zovi/presentation/profile/add_plan/model/add_plan_success_route_args.dart';
import 'package:zovi/presentation/profile/add_plan/view/add_plan_view.dart';
import 'package:zovi/presentation/profile/add_plan/view/add_plan_details_view.dart';
import 'package:zovi/presentation/profile/add_plan/view/add_plan_success_view.dart';
import 'package:zovi/presentation/profile/view/profile_view.dart';
import 'package:zovi/presentation/stories/bloc/stories_bloc.dart';
import 'package:zovi/presentation/stories/view/stories_view.dart';

abstract final class AppRouter {
  static final GlobalKey<NavigatorState> rootKey = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> shellKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: RoutePaths.splash.path,
    routes: [
      GoRoute(
        path: RoutePaths.splash.path,
        name: RoutePaths.splash.name,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<SplashBloc>(),
          child: const SplashView(),
        ),
      ),
      GoRoute(
        path: RoutePaths.intro.path,
        name: RoutePaths.intro.name,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<IntroBloc>(),
          child: const IntroView(),
        ),
      ),
      GoRoute(
        path: RoutePaths.onboarding.path,
        name: RoutePaths.onboarding.name,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<OnboardingBloc>(),
          child: const OnboardingView(),
        ),
      ),
      GoRoute(
        path: RoutePaths.otp.path,
        name: RoutePaths.otp.name,
        redirect: (context, state) {
          if (state.extra is! OtpRouteArgs) {
            return RoutePaths.onboarding.path;
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra! as OtpRouteArgs;
          return BlocProvider(
            create: (_) => OtpBloc(
              getIt(),
              phone: args.phone,
              selectedCountry: args.selectedCountry,
            ),
            child: const OtpView(),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.phoneVerified.path,
        name: RoutePaths.phoneVerified.name,
        builder: (context, state) => const PhoneVerifiedView(),
      ),
      GoRoute(
        path: RoutePaths.createProfile.path,
        name: RoutePaths.createProfile.name,
        redirect: (context, state) {
          if (state.extra is! CreateProfileRouteArgs) {
            return RoutePaths.onboarding.path;
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra! as CreateProfileRouteArgs;
          return BlocProvider(
            create: (_) => CreateProfileBloc(signupFlow: args.signupFlow),
            child: CreateProfileView(signupFlow: args.signupFlow),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.birthday.path,
        name: RoutePaths.birthday.name,
        redirect: (context, state) {
          if (state.extra is! BirthdayRouteArgs) {
            return RoutePaths.onboarding.path;
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra! as BirthdayRouteArgs;
          return BlocProvider(
            create: (_) => BirthdayBloc(signupFlow: args.signupFlow),
            child: BirthdayView(signupFlow: args.signupFlow),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.notificationPermission.path,
        name: RoutePaths.notificationPermission.name,
        redirect: (context, state) {
          if (state.extra is! NotificationPermissionRouteArgs) {
            return RoutePaths.onboarding.path;
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra! as NotificationPermissionRouteArgs;
          return BlocProvider(
            create: (_) =>
                NotificationPermissionBloc(signupFlow: args.signupFlow),
            child: const NotificationPermissionView(),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.locationPermission.path,
        name: RoutePaths.locationPermission.name,
        builder: (context, state) => BlocProvider(
          create: (_) => LocationPermissionBloc(getIt<AuthRepository>()),
          child: const LocationPermissionView(),
        ),
      ),
      ShellRoute(
        navigatorKey: shellKey,
        builder: (context, state, child) => MainWrapper(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.home.path,
            name: RoutePaths.home.name,
            builder: (context, state) => BlocProvider(
              create: (_) => getIt<HomeBloc>(),
              child: const HomeView(),
            ),
          ),
          GoRoute(
            path: RoutePaths.stories.path,
            name: RoutePaths.stories.name,
            builder: (context, state) => BlocProvider(
              create: (_) => getIt<StoriesBloc>(),
              child: const StoriesView(),
            ),
          ),
          GoRoute(
            path: RoutePaths.chat.path,
            name: RoutePaths.chat.name,
            builder: (context, state) => BlocProvider(
              create: (_) => getIt<ChatBloc>(),
              child: const ChatView(),
            ),
          ),
          GoRoute(
            path: RoutePaths.profile.path,
            name: RoutePaths.profile.name,
            builder: (context, state) => BlocProvider(
              create: (_) => getIt<ProfileBloc>(),
              child: const ProfileView(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.editProfile.path,
        name: RoutePaths.editProfile.name,
        redirect: (context, state) {
          if (state.extra is! EditProfileRouteArgs) {
            return RoutePaths.profile.path;
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra! as EditProfileRouteArgs;
          return EditProfileView(user: args.user);
        },
      ),
      GoRoute(
        path: RoutePaths.editProfileField.path,
        name: RoutePaths.editProfileField.name,
        redirect: (context, state) {
          if (state.extra is! EditProfileFieldRouteArgs) {
            return RoutePaths.profile.path;
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra! as EditProfileFieldRouteArgs;
          return EditProfileFieldView(
            field: args.field,
            initialValue: args.initialValue,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.editProfileLinks.path,
        name: RoutePaths.editProfileLinks.name,
        redirect: (context, state) {
          if (state.extra is! EditProfileLinksRouteArgs) {
            return RoutePaths.profile.path;
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra! as EditProfileLinksRouteArgs;
          return EditProfileLinksView(links: args.links);
        },
      ),
      GoRoute(
        path: RoutePaths.addProfileLink.path,
        name: RoutePaths.addProfileLink.name,
        builder: (context, state) => const AddProfileLinkView(),
      ),
      GoRoute(
        path: RoutePaths.addPlan.path,
        name: RoutePaths.addPlan.name,
        builder: (context, state) => const AddPlanView(),
      ),
      GoRoute(
        path: RoutePaths.addPlanDetails.path,
        name: RoutePaths.addPlanDetails.name,
        redirect: (context, state) {
          if (state.extra is! AddPlanDetailsRouteArgs) {
            return RoutePaths.addPlan.path;
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra! as AddPlanDetailsRouteArgs;
          return AddPlanDetailsView(place: args.place);
        },
      ),
      GoRoute(
        path: RoutePaths.addPlanSuccess.path,
        name: RoutePaths.addPlanSuccess.name,
        redirect: (context, state) {
          if (state.extra is! AddPlanSuccessRouteArgs) {
            return RoutePaths.profile.path;
          }
          return null;
        },
        builder: (context, state) {
          final args = state.extra! as AddPlanSuccessRouteArgs;
          return AddPlanSuccessView(
            friendAvatars: args.place.friendAvatars,
            friendsLabel: args.place.friendsLabel,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.discover.path,
        name: RoutePaths.discover.name,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<DiscoverBloc>(),
          child: const DiscoverView(),
        ),
      ),
    ],
  );
}
