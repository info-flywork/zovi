import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zovi/core/managers/auth_cache_manager.dart';
import 'package:zovi/core/managers/shared_pref_manager.dart';
import 'package:zovi/core/network/dio_client.dart';
import 'package:zovi/core/network/network_manager.dart';
import 'package:zovi/domain/auth/auth_repository.dart';
import 'package:zovi/domain/user/user_repository.dart';
import 'package:zovi/presentation/auth/create_profile/bloc/create_profile_bloc.dart';
import 'package:zovi/presentation/auth/intro/bloc/intro_bloc.dart';
import 'package:zovi/presentation/auth/onboarding/bloc/onboarding_bloc.dart';
import 'package:zovi/presentation/auth/splash/bloc/splash_bloc.dart';
import 'package:zovi/presentation/chat/bloc/chat_bloc.dart';
import 'package:zovi/presentation/discover/bloc/discover_bloc.dart';
import 'package:zovi/presentation/home/bloc/home_bloc.dart';
import 'package:zovi/presentation/profile/bloc/profile_bloc.dart';
import 'package:zovi/presentation/stories/bloc/stories_bloc.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (getIt.isRegistered<CreateProfileBloc>()) {
    await getIt.unregister<CreateProfileBloc>();
  }

  if (getIt.isRegistered<AuthRepository>()) return;

  final prefs = await SharedPreferences.getInstance();

  getIt
    ..registerLazySingleton(() => DioClient.create())
    ..registerLazySingleton(() => NetworkManager(getIt()))
    ..registerLazySingleton(() => SharedPrefManager(prefs))
    ..registerLazySingleton(
      () => AuthCacheManager(const FlutterSecureStorage()),
    )
    ..registerLazySingleton(() => AuthRepository(getIt(), getIt()))
    ..registerLazySingleton(UserRepository.new)
    ..registerFactory(() => SplashBloc(getIt()))
    ..registerFactory(() => IntroBloc(getIt()))
    ..registerFactory(() => OnboardingBloc(getIt()))
    ..registerFactory(() => HomeBloc(getIt()))
    ..registerFactory(() => StoriesBloc(getIt()))
    ..registerFactory(() => ChatBloc())
    ..registerFactory(() => ProfileBloc(getIt()))
    ..registerFactory(() => DiscoverBloc());
}
